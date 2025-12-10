import Foundation

/// Analytics event model matching the backend schema
public struct AnalyticsEvent: Codable {
    public let siteId: String
    public let sessionId: String
    public let userId: String
    public let eventType: String
    public let pageUrl: String
    public let pageTitle: String?
    public let referrer: String?
    public let deviceType: String
    public let userAgent: String
    public let isLoggedIn: Bool
    public let timestamp: Date
    public let duration: Int?
    public let scrollDepth: Int?
    public let customData: String?

    // Video fields
    public let videoId: String?
    public let videoTitle: String?
    public let videoDuration: Float?
    public let videoPosition: Float?
    public let videoPercent: Int?

    // Article metadata fields (matching web tracker)
    public let creator: String?
    public let articleAuthor: String?
    public let articleSection: String?
    public let articleKeywords: [String]?
    public let publishedDate: String?
    public let contentType: String?

    // Navigation tracking
    public let previousPageUrl: String?
    public let previousPageTitle: String?

    // Screen dimensions
    public let screenWidth: Int?
    public let screenHeight: Int?

    // UTM Campaign parameters
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmContent: String?
    public let utmTerm: String?

    enum CodingKeys: String, CodingKey {
        case siteId = "site_id"
        case sessionId = "session_id"
        case userId = "user_id"
        case eventType = "event_type"
        case pageUrl = "page_url"
        case pageTitle = "page_title"
        case referrer
        case deviceType = "device_type"
        case userAgent = "user_agent"
        case isLoggedIn = "is_logged_in"
        case timestamp
        case duration
        case scrollDepth = "scroll_depth"
        case customData = "custom_data"
        case videoId = "video_id"
        case videoTitle = "video_title"
        case videoDuration = "video_duration"
        case videoPosition = "video_position"
        case videoPercent = "video_percent"
        // Article metadata
        case creator
        case articleAuthor = "article_author"
        case articleSection = "article_section"
        case articleKeywords = "article_keywords"
        case publishedDate = "published_date"
        case contentType = "content_type"
        // Navigation
        case previousPageUrl = "previous_page_url"
        case previousPageTitle = "previous_page_title"
        // Screen
        case screenWidth = "screen_width"
        case screenHeight = "screen_height"
        // UTM
        case utmSource = "utm_source"
        case utmMedium = "utm_medium"
        case utmCampaign = "utm_campaign"
        case utmContent = "utm_content"
        case utmTerm = "utm_term"
    }

    public init(
        siteId: String,
        sessionId: String,
        userId: String,
        eventType: String,
        pageUrl: String,
        pageTitle: String? = nil,
        referrer: String? = nil,
        deviceType: String,
        userAgent: String,
        isLoggedIn: Bool = false,
        timestamp: Date = Date(),
        duration: Int? = nil,
        scrollDepth: Int? = nil,
        customData: String? = nil,
        videoId: String? = nil,
        videoTitle: String? = nil,
        videoDuration: Float? = nil,
        videoPosition: Float? = nil,
        videoPercent: Int? = nil,
        creator: String? = nil,
        articleAuthor: String? = nil,
        articleSection: String? = nil,
        articleKeywords: [String]? = nil,
        publishedDate: String? = nil,
        contentType: String? = nil,
        previousPageUrl: String? = nil,
        previousPageTitle: String? = nil,
        screenWidth: Int? = nil,
        screenHeight: Int? = nil,
        utmSource: String? = nil,
        utmMedium: String? = nil,
        utmCampaign: String? = nil,
        utmContent: String? = nil,
        utmTerm: String? = nil
    ) {
        self.siteId = siteId
        self.sessionId = sessionId
        self.userId = userId
        self.eventType = eventType
        self.pageUrl = pageUrl
        self.pageTitle = pageTitle
        self.referrer = referrer
        self.deviceType = deviceType
        self.userAgent = userAgent
        self.isLoggedIn = isLoggedIn
        self.timestamp = timestamp
        self.duration = duration
        self.scrollDepth = scrollDepth
        self.customData = customData
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.videoDuration = videoDuration
        self.videoPosition = videoPosition
        self.videoPercent = videoPercent
        self.creator = creator
        self.articleAuthor = articleAuthor
        self.articleSection = articleSection
        self.articleKeywords = articleKeywords
        self.publishedDate = publishedDate
        self.contentType = contentType
        self.previousPageUrl = previousPageUrl
        self.previousPageTitle = previousPageTitle
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.utmSource = utmSource
        self.utmMedium = utmMedium
        self.utmCampaign = utmCampaign
        self.utmContent = utmContent
        self.utmTerm = utmTerm
    }
}

/// Screen metadata for article/content tracking
public struct ScreenMetadata {
    /// Content creator/editor (e.g., "Dijital Haber Merkezi")
    public let creator: String?

    /// Article authors (e.g., ["Ahmet Hakan", "Mehmet Yılmaz"])
    public let authors: [String]?

    /// Content section/category (e.g., "Spor", "Ekonomi")
    public let section: String?

    /// Content keywords/tags
    public let keywords: [String]?

    /// Publication date
    public let publishedDate: Date?

    /// Content type (e.g., "article", "video", "gallery", "live")
    public let contentType: String?

    public init(
        creator: String? = nil,
        authors: [String]? = nil,
        section: String? = nil,
        keywords: [String]? = nil,
        publishedDate: Date? = nil,
        contentType: String? = nil
    ) {
        self.creator = creator
        self.authors = authors
        self.section = section
        self.keywords = keywords
        self.publishedDate = publishedDate
        self.contentType = contentType
    }
}

/// UTM parameters for campaign tracking (from deep links)
public struct UTMParameters {
    public let source: String?
    public let medium: String?
    public let campaign: String?
    public let content: String?
    public let term: String?

    public init(
        source: String? = nil,
        medium: String? = nil,
        campaign: String? = nil,
        content: String? = nil,
        term: String? = nil
    ) {
        self.source = source
        self.medium = medium
        self.campaign = campaign
        self.content = content
        self.term = term
    }

    /// Parse UTM parameters from a URL
    public static func from(url: URL) -> UTMParameters {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return UTMParameters()
        }

        let queryItems = components.queryItems ?? []
        return UTMParameters(
            source: queryItems.first { $0.name == "utm_source" }?.value,
            medium: queryItems.first { $0.name == "utm_medium" }?.value,
            campaign: queryItems.first { $0.name == "utm_campaign" }?.value,
            content: queryItems.first { $0.name == "utm_content" }?.value,
            term: queryItems.first { $0.name == "utm_term" }?.value
        )
    }
}

/// Stored event for offline persistence
struct StoredEvent: Codable {
    let id: String
    let event: AnalyticsEvent
    let createdAt: Date
    var retryCount: Int

    init(event: AnalyticsEvent) {
        self.id = UUID().uuidString
        self.event = event
        self.createdAt = Date()
        self.retryCount = 0
    }
}
