import Foundation

/// SDK configuration
public struct DMBIConfiguration {
    /// Site identifier (e.g., "hurriyet-ios", "cnnturk-ios")
    public let siteId: String

    /// Analytics endpoint URL
    public let endpoint: URL

    /// Heartbeat interval in seconds (default: 30)
    public var heartbeatInterval: TimeInterval = 30

    /// Maximum heartbeat interval when user is inactive (default: 120)
    public var maxHeartbeatInterval: TimeInterval = 120

    /// Time without interaction before increasing heartbeat interval (default: 30)
    public var inactivityThreshold: TimeInterval = 30

    /// Batch size for event sending (default: 10)
    public var batchSize: Int = 10

    /// Flush interval in seconds (default: 30)
    public var flushInterval: TimeInterval = 30

    /// Maximum retry count for failed events (default: 3)
    public var maxRetryCount: Int = 3

    /// Session timeout in seconds - new session after background (default: 30 minutes)
    public var sessionTimeout: TimeInterval = 30 * 60

    /// Enable debug logging (default: false)
    public var debugLogging: Bool = false

    /// Maximum offline events to store (default: 1000)
    public var maxOfflineEvents: Int = 1000

    /// Days to keep offline events (default: 7)
    public var offlineRetentionDays: Int = 7

    /// Enable automatic scroll tracking when possible (default: true)
    public var autoScrollTracking: Bool = true

    public init(siteId: String, endpoint: String) {
        self.siteId = siteId
        self.endpoint = URL(string: endpoint)!
    }

    public init(siteId: String, endpoint: URL) {
        self.siteId = siteId
        self.endpoint = endpoint
    }
}
