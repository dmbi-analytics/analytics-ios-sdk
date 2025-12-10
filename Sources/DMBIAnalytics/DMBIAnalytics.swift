import Foundation

/// DMBI Analytics SDK for iOS
/// Tracks user activity, screen views, video engagement, and push notifications
public final class DMBIAnalytics {
    /// Shared instance
    public static let shared = DMBIAnalytics()

    private var config: DMBIConfiguration?
    private var sessionManager: SessionManager?
    private var networkQueue: NetworkQueue?
    private var offlineStore: OfflineStore?
    private var eventTracker: EventTracker?
    private var heartbeatManager: HeartbeatManager?
    private var lifecycleTracker: LifecycleTracker?

    private var isConfigured = false

    private init() {}

    // MARK: - Configuration

    /// Configure the SDK with site ID and endpoint
    /// - Parameters:
    ///   - siteId: Your site identifier (e.g., "hurriyet-ios")
    ///   - endpoint: Analytics endpoint URL (e.g., "https://realtime.dmbi.site/e")
    public static func configure(siteId: String, endpoint: String) {
        let config = DMBIConfiguration(siteId: siteId, endpoint: endpoint)
        shared.configure(with: config)
    }

    /// Configure the SDK with a custom configuration
    /// - Parameter config: DMBIConfiguration instance
    public static func configure(with config: DMBIConfiguration) {
        shared.configure(with: config)
    }

    private func configure(with config: DMBIConfiguration) {
        guard !isConfigured else {
            if config.debugLogging {
                print("[DMBIAnalytics] Already configured. Ignoring duplicate configuration.")
            }
            return
        }

        self.config = config

        // Initialize components
        sessionManager = SessionManager(sessionTimeout: config.sessionTimeout)

        offlineStore = OfflineStore(
            maxEvents: config.maxOfflineEvents,
            retentionDays: config.offlineRetentionDays
        )

        networkQueue = NetworkQueue(
            endpoint: config.endpoint,
            batchSize: config.batchSize,
            flushInterval: config.flushInterval,
            maxRetryCount: config.maxRetryCount,
            debugLogging: config.debugLogging
        )
        networkQueue?.setOfflineStore(offlineStore!)

        eventTracker = EventTracker(
            config: config,
            sessionManager: sessionManager!,
            networkQueue: networkQueue!
        )

        heartbeatManager = HeartbeatManager(interval: config.heartbeatInterval)
        heartbeatManager?.setTracker(eventTracker!)

        lifecycleTracker = LifecycleTracker(sessionTimeout: config.sessionTimeout)
        lifecycleTracker?.configure(
            tracker: eventTracker!,
            sessionManager: sessionManager!,
            heartbeatManager: heartbeatManager!
        )

        // Start heartbeat
        heartbeatManager?.start()

        isConfigured = true

        if config.debugLogging {
            print("[DMBIAnalytics] Configured with siteId: \(config.siteId)")
        }
    }

    // MARK: - Screen Tracking

    /// Track a screen view (simple version)
    /// - Parameters:
    ///   - name: Screen name (e.g., "ArticleDetail", "Home")
    ///   - url: Screen URL (e.g., "app://article/123")
    ///   - title: Optional screen title
    public static func trackScreen(name: String, url: String, title: String? = nil) {
        shared.eventTracker?.trackScreen(name: name, url: url, title: title, metadata: nil)
    }

    /// Track a screen view with article metadata
    /// - Parameters:
    ///   - name: Screen name (e.g., "ArticleDetail", "Home")
    ///   - url: Screen URL (e.g., "app://article/123")
    ///   - title: Optional screen title
    ///   - metadata: Article metadata (authors, section, keywords, etc.)
    public static func trackScreen(name: String, url: String, title: String? = nil, metadata: ScreenMetadata) {
        shared.eventTracker?.trackScreen(name: name, url: url, title: title, metadata: metadata)
    }

    // MARK: - Deep Link & UTM Tracking

    /// Handle a deep link URL and extract UTM parameters
    /// Call this when your app opens from a deep link
    /// - Parameter url: The deep link URL
    public static func handleDeepLink(url: URL) {
        shared.eventTracker?.handleDeepLink(url: url)
    }

    /// Set UTM parameters manually
    /// - Parameter utm: UTM parameters
    public static func setUTMParameters(_ utm: UTMParameters) {
        shared.eventTracker?.setUTMParameters(utm)
    }

    /// Set referrer source manually
    /// - Parameter referrer: Referrer identifier (e.g., "facebook", "twitter", "push_notification")
    public static func setReferrer(_ referrer: String) {
        shared.eventTracker?.setReferrer(referrer)
    }

    // MARK: - Video Tracking

    /// Track video impression (video appeared on screen)
    /// - Parameters:
    ///   - videoId: Unique video identifier
    ///   - title: Optional video title
    ///   - duration: Optional video duration in seconds
    public static func trackVideoImpression(videoId: String, title: String? = nil, duration: Float? = nil) {
        shared.eventTracker?.trackVideoImpression(videoId: videoId, title: title, duration: duration)
    }

    /// Track video play start
    /// - Parameters:
    ///   - videoId: Unique video identifier
    ///   - title: Optional video title
    ///   - duration: Optional video duration in seconds
    ///   - position: Optional current playback position in seconds
    public static func trackVideoPlay(videoId: String, title: String? = nil, duration: Float? = nil, position: Float? = nil) {
        shared.eventTracker?.trackVideoPlay(videoId: videoId, title: title, duration: duration, position: position)
    }

    /// Track video progress (25%, 50%, 75%, etc.)
    /// - Parameters:
    ///   - videoId: Unique video identifier
    ///   - duration: Video duration in seconds
    ///   - position: Current playback position in seconds
    ///   - percent: Watch percentage (25, 50, 75, etc.)
    public static func trackVideoProgress(videoId: String, duration: Float? = nil, position: Float? = nil, percent: Int) {
        shared.eventTracker?.trackVideoProgress(videoId: videoId, duration: duration, position: position, percent: percent)
    }

    /// Track video pause
    /// - Parameters:
    ///   - videoId: Unique video identifier
    ///   - position: Current playback position in seconds
    ///   - percent: Watch percentage when paused
    public static func trackVideoPause(videoId: String, position: Float? = nil, percent: Int? = nil) {
        shared.eventTracker?.trackVideoPause(videoId: videoId, position: position, percent: percent)
    }

    /// Track video completion
    /// - Parameters:
    ///   - videoId: Unique video identifier
    ///   - duration: Video duration in seconds
    public static func trackVideoComplete(videoId: String, duration: Float? = nil) {
        shared.eventTracker?.trackVideoComplete(videoId: videoId, duration: duration)
    }

    // MARK: - Push Notification Tracking

    /// Track push notification received
    /// - Parameters:
    ///   - notificationId: Optional notification identifier
    ///   - title: Optional notification title
    ///   - campaign: Optional campaign identifier
    public static func trackPushReceived(notificationId: String? = nil, title: String? = nil, campaign: String? = nil) {
        shared.eventTracker?.trackPushReceived(notificationId: notificationId, title: title, campaign: campaign)
    }

    /// Track push notification opened
    /// - Parameters:
    ///   - notificationId: Optional notification identifier
    ///   - title: Optional notification title
    ///   - campaign: Optional campaign identifier
    public static func trackPushOpened(notificationId: String? = nil, title: String? = nil, campaign: String? = nil) {
        shared.eventTracker?.trackPushOpened(notificationId: notificationId, title: title, campaign: campaign)
    }

    // MARK: - User State

    /// Set user login state
    /// - Parameter loggedIn: Whether the user is logged in
    public static func setLoggedIn(_ loggedIn: Bool) {
        shared.eventTracker?.setLoggedIn(loggedIn)
    }

    // MARK: - Custom Events

    /// Track a custom event
    /// - Parameters:
    ///   - name: Event name
    ///   - properties: Optional event properties
    public static func trackEvent(name: String, properties: [String: Any]? = nil) {
        shared.eventTracker?.trackCustomEvent(name: name, properties: properties)
    }

    // MARK: - Control

    /// Flush all pending events immediately
    public static func flush() {
        shared.eventTracker?.flush()
    }

    /// Enable or disable debug logging
    /// - Parameter enabled: Whether debug logging is enabled
    public static func setDebugLogging(_ enabled: Bool) {
        shared.config?.debugLogging = enabled
    }
}
