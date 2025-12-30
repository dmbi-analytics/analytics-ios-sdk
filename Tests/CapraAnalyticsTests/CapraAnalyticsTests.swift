import XCTest
@testable import CapraAnalytics

final class CapraAnalyticsTests: XCTestCase {

    func testEventCreation() throws {
        let event = AnalyticsEvent(
            siteId: "test-site",
            sessionId: "session-123",
            userId: "user-456",
            eventType: "screen_view",
            pageUrl: "app://home",
            pageTitle: "Home Screen",
            deviceType: "ios_phone",
            userAgent: "CapraAnalytics/2.0.0 iOS/17.0"
        )

        XCTAssertEqual(event.siteId, "test-site")
        XCTAssertEqual(event.sessionId, "session-123")
        XCTAssertEqual(event.eventType, "screen_view")
        XCTAssertEqual(event.pageUrl, "app://home")
    }

    func testEventEncoding() throws {
        let event = AnalyticsEvent(
            siteId: "test-site",
            sessionId: "session-123",
            userId: "user-456",
            eventType: "screen_view",
            pageUrl: "app://home",
            deviceType: "ios_phone",
            userAgent: "CapraAnalytics/2.0.0"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode([event])

        XCTAssertNotNil(data)

        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("site_id"))
        XCTAssertTrue(jsonString.contains("session_id"))
        XCTAssertTrue(jsonString.contains("event_type"))
    }

    func testConfigurationDefaults() throws {
        let config = CapraConfiguration(siteId: "test", endpoint: "https://example.com/e")

        XCTAssertEqual(config.siteId, "test")
        XCTAssertEqual(config.heartbeatInterval, 60)
        XCTAssertEqual(config.batchSize, 10)
        XCTAssertEqual(config.flushInterval, 30)
        XCTAssertEqual(config.sessionTimeout, 30 * 60)
        XCTAssertFalse(config.debugLogging)
    }
}
