import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// DMBI Analytics SDK for iOS
/// Tracks user activity, screen views, video engagement, and push notifications
///
/// Features:
/// - Heartbeat tracking with dynamic intervals
/// - Active time tracking (excluding background)
/// - Scroll depth tracking
/// - User segments and types
/// - Conversion tracking
/// - Offline event storage
/// - Event batching
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
    private var scrollTracker: ScrollTracker?

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

        // Initialize scroll tracker
        scrollTracker = ScrollTracker()

        eventTracker = EventTracker(
            config: config,
            sessionManager: sessionManager!,
            networkQueue: networkQueue!
        )
        eventTracker?.setScrollTracker(scrollTracker!)

        heartbeatManager = HeartbeatManager(
            interval: config.heartbeatInterval,
            maxInterval: config.maxHeartbeatInterval,
            inactivityThreshold: config.inactivityThreshold
        )
        heartbeatManager?.setTracker(eventTracker!)

        // Connect heartbeat manager to event tracker for interaction recording
        eventTracker?.setHeartbeatManager(heartbeatManager!)

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
            print("[DMBIAnalytics] Configured with siteId: \(config.siteId), heartbeat: \(config.heartbeatInterval)s")
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

    // MARK: - Scroll Tracking

    /// Get the scroll tracker for attaching to scroll views
    /// - Returns: ScrollTracker instance
    public static func getScrollTracker() -> ScrollTracker? {
        return shared.scrollTracker
    }

    #if os(iOS) || os(tvOS)
    /// Attach scroll tracking to a UIScrollView (or subclass like UITableView, UICollectionView)
    /// - Parameter scrollView: The scroll view to track
    public static func attachScrollTracking(to scrollView: UIScrollView) {
        shared.scrollTracker?.attach(to: scrollView)
    }
    #endif

    /// Report scroll depth manually (for custom scroll implementations like SwiftUI)
    /// - Parameter percent: Scroll percentage (0-100)
    public static func reportScrollDepth(_ percent: Int) {
        shared.eventTracker?.reportScrollDepth(percent)
    }

    /// Get current maximum scroll depth
    /// - Returns: Scroll depth percentage (0-100)
    public static func getCurrentScrollDepth() -> Int {
        return shared.eventTracker?.getCurrentScrollDepth() ?? 0
    }

    /// Detach scroll tracking from current view
    public static func detachScrollTracking() {
        shared.scrollTracker?.detach()
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
    public static func trackVideoImpression(videoId: String, title: String? = nil, duration: Float? = nil) {
        shared.eventTracker?.trackVideoImpression(videoId: videoId, title: title, duration: duration)
    }

    /// Track video play start
    public static func trackVideoPlay(videoId: String, title: String? = nil, duration: Float? = nil, position: Float? = nil) {
        shared.eventTracker?.trackVideoPlay(videoId: videoId, title: title, duration: duration, position: position)
    }

    /// Track video progress (25%, 50%, 75%, etc.)
    public static func trackVideoProgress(videoId: String, duration: Float? = nil, position: Float? = nil, percent: Int) {
        shared.eventTracker?.trackVideoProgress(videoId: videoId, duration: duration, position: position, percent: percent)
    }

    /// Track video pause
    public static func trackVideoPause(videoId: String, position: Float? = nil, percent: Int? = nil) {
        shared.eventTracker?.trackVideoPause(videoId: videoId, position: position, percent: percent)
    }

    /// Track video completion
    public static func trackVideoComplete(videoId: String, duration: Float? = nil) {
        shared.eventTracker?.trackVideoComplete(videoId: videoId, duration: duration)
    }

    // MARK: - Push Notification Tracking

    /// Track push notification received
    public static func trackPushReceived(notificationId: String? = nil, title: String? = nil, campaign: String? = nil) {
        shared.eventTracker?.trackPushReceived(notificationId: notificationId, title: title, campaign: campaign)
    }

    /// Track push notification opened
    public static func trackPushOpened(notificationId: String? = nil, title: String? = nil, campaign: String? = nil) {
        shared.eventTracker?.trackPushOpened(notificationId: notificationId, title: title, campaign: campaign)
    }

    // MARK: - User State

    /// Set user login state
    /// - Parameter loggedIn: Whether the user is logged in
    public static func setLoggedIn(_ loggedIn: Bool) {
        shared.eventTracker?.setLoggedIn(loggedIn)
    }

    /// Set user type (anonymous, logged, subscriber, premium)
    /// - Parameter userType: The user's subscription/login status
    public static func setUserType(_ userType: UserType) {
        shared.eventTracker?.setUserType(userType)
    }

    // MARK: - User Segments

    /// Add a user segment for cohort analysis
    /// - Parameter segment: Segment identifier (e.g., "sports_fan", "premium_reader")
    public static func addUserSegment(_ segment: String) {
        shared.eventTracker?.addUserSegment(segment)
    }

    /// Remove a user segment
    /// - Parameter segment: Segment identifier to remove
    public static func removeUserSegment(_ segment: String) {
        shared.eventTracker?.removeUserSegment(segment)
    }

    /// Set all user segments (replaces existing)
    /// - Parameter segments: Set of segment identifiers
    public static func setUserSegments(_ segments: Set<String>) {
        shared.eventTracker?.setUserSegments(segments)
    }

    /// Clear all user segments
    public static func clearUserSegments() {
        shared.eventTracker?.clearUserSegments()
    }

    /// Get current user segments
    /// - Returns: Set of segment identifiers
    public static func getUserSegments() -> Set<String> {
        return shared.eventTracker?.getUserSegments() ?? []
    }

    // MARK: - Conversion Tracking

    /// Track a conversion event
    /// - Parameter conversion: Conversion details
    public static func trackConversion(_ conversion: Conversion) {
        shared.eventTracker?.trackConversion(conversion)
    }

    /// Track a simple conversion
    /// - Parameters:
    ///   - id: Unique conversion identifier
    ///   - type: Conversion type (e.g., "subscription", "registration", "purchase")
    ///   - value: Optional conversion value (e.g., revenue amount)
    ///   - currency: Optional currency code (e.g., "TRY", "USD")
    public static func trackConversion(id: String, type: String, value: Double? = nil, currency: String? = nil) {
        shared.eventTracker?.trackConversion(Conversion(id: id, type: type, value: value, currency: currency))
    }

    // MARK: - Custom Events

    /// Track a custom event
    /// - Parameters:
    ///   - name: Event name
    ///   - properties: Optional event properties
    public static func trackEvent(name: String, properties: [String: Any]? = nil) {
        shared.eventTracker?.trackCustomEvent(name: name, properties: properties)
    }

    // MARK: - User Interaction

    /// Record user interaction (resets inactivity timer for dynamic heartbeat)
    /// Call this on touch events, scrolls, or other user actions
    public static func recordInteraction() {
        shared.eventTracker?.recordInteraction()
    }

    // MARK: - Engagement Metrics

    /// Get current active time in seconds (excluding background time)
    /// - Returns: Active time in seconds
    public static func getActiveTimeSeconds() -> Int {
        return shared.heartbeatManager?.activeTimeSeconds ?? 0
    }

    /// Get current ping counter
    /// - Returns: Number of heartbeats sent in current session
    public static func getPingCounter() -> Int {
        return shared.heartbeatManager?.currentPingCounter ?? 0
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
