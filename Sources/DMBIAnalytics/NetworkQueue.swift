import Foundation

/// Handles batching and sending events to the server
final class NetworkQueue {
    private let endpoint: URL
    private let batchSize: Int
    private let flushInterval: TimeInterval
    private let maxRetryCount: Int
    private let debugLogging: Bool

    private var eventQueue: [AnalyticsEvent] = []
    private var flushTimer: Timer?
    private let queue = DispatchQueue(label: "site.dmbi.analytics.network", qos: .utility)
    private let urlSession: URLSession

    private var offlineStore: OfflineStore?

    init(endpoint: URL, batchSize: Int, flushInterval: TimeInterval, maxRetryCount: Int, debugLogging: Bool) {
        self.endpoint = endpoint
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.maxRetryCount = maxRetryCount
        self.debugLogging = debugLogging

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)

        startFlushTimer()
    }

    func setOfflineStore(_ store: OfflineStore) {
        self.offlineStore = store
    }

    /// Add event to queue
    func enqueue(_ event: AnalyticsEvent) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.eventQueue.append(event)

            if self.eventQueue.count >= self.batchSize {
                self.flush()
            }
        }
    }

    /// Flush all queued events
    func flush() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard !self.eventQueue.isEmpty else { return }

            let eventsToSend = self.eventQueue
            self.eventQueue.removeAll()

            self.sendEvents(eventsToSend)
        }
    }

    /// Send events to server
    private func sendEvents(_ events: [AnalyticsEvent]) {
        guard !events.isEmpty else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            if debugLogging {
                print("[DMBIAnalytics] Sending \(events.count) events to \(endpoint)")
            }

            let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                if let error = error {
                    if self.debugLogging {
                        print("[DMBIAnalytics] Network error: \(error.localizedDescription)")
                    }
                    // Store events offline for retry
                    self.storeOffline(events)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.storeOffline(events)
                    return
                }

                if httpResponse.statusCode == 202 {
                    if self.debugLogging {
                        print("[DMBIAnalytics] Successfully sent \(events.count) events")
                    }
                } else {
                    if self.debugLogging {
                        print("[DMBIAnalytics] Server returned status \(httpResponse.statusCode)")
                    }
                    if httpResponse.statusCode >= 500 {
                        // Server error - retry later
                        self.storeOffline(events)
                    }
                    // Don't retry 4xx errors - they're client errors
                }
            }
            task.resume()

        } catch {
            if debugLogging {
                print("[DMBIAnalytics] Failed to encode events: \(error)")
            }
        }
    }

    /// Store events offline for later retry
    private func storeOffline(_ events: [AnalyticsEvent]) {
        guard let store = offlineStore else { return }
        for event in events {
            store.store(event)
        }
    }

    /// Retry sending offline events
    func retryOfflineEvents() {
        guard let store = offlineStore else { return }

        let storedEvents = store.fetchPendingEvents()
        guard !storedEvents.isEmpty else { return }

        if debugLogging {
            print("[DMBIAnalytics] Retrying \(storedEvents.count) offline events")
        }

        let events = storedEvents.map { $0.event }
        let ids = storedEvents.map { $0.id }

        sendEventsWithCompletion(events) { [weak self] success in
            if success {
                self?.offlineStore?.delete(ids: ids)
            } else {
                // Increment retry count
                for id in ids {
                    self?.offlineStore?.incrementRetry(id: id, maxRetries: self?.maxRetryCount ?? 3)
                }
            }
        }
    }

    private func sendEventsWithCompletion(_ events: [AnalyticsEvent], completion: @escaping (Bool) -> Void) {
        guard !events.isEmpty else {
            completion(true)
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let task = urlSession.dataTask(with: request) { data, response, error in
                if error != nil {
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 202 else {
                    completion(false)
                    return
                }

                completion(true)
            }
            task.resume()

        } catch {
            completion(false)
        }
    }

    // MARK: - Timer

    private func startFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.flushTimer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    func stopFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = nil
    }

    deinit {
        stopFlushTimer()
    }
}
