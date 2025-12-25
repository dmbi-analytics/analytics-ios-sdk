# DMBI Analytics iOS SDK

Native iOS SDK for DMBI Analytics platform. Track screen views, video engagement, push notifications, scroll depth, conversions, and custom events.

## Features

- **Heartbeat with Dynamic Intervals**: 30s base interval, increases to 120s when user is inactive
- **Active Time Tracking**: Only counts foreground time, excludes background
- **Scroll Depth Tracking**: UIScrollView, UITableView, UICollectionView support
- **User Segments**: Cohort analysis with custom segments
- **Conversion Tracking**: Track subscriptions, purchases, registrations
- **Offline Support**: Events are queued and sent when network is available
- **Automatic Session Management**: New session after 30 min background

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dmbi-analytics/analytics-ios-sdk.git", from: "1.0.9")
]
```

Or in Xcode: File > Add Packages > Enter URL: `https://github.com/dmbi-analytics/analytics-ios-sdk.git`

### CocoaPods

```ruby
pod 'DMBIAnalytics', '~> 1.0.9'
```

## Quick Start

### 1. Initialize in AppDelegate

```swift
import DMBIAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DMBIAnalytics.configure(
            siteId: "your-site-ios",
            endpoint: "https://realtime.dmbi.site/e"
        )

        return true
    }
}
```

### 2. Track Screens

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DMBIAnalytics.trackScreen(
        name: "ArticleDetail",
        url: "app://article/\(articleId)",
        title: article.title
    )
}
```

### 3. Scroll Tracking

```swift
// Attach to UIScrollView, UITableView, or UICollectionView
DMBIAnalytics.attachScrollTracking(to: tableView)

// Or report manually (for SwiftUI or custom implementations)
DMBIAnalytics.reportScrollDepth(75) // 75%

// Get current scroll depth
let depth = DMBIAnalytics.getCurrentScrollDepth()

// Detach when leaving screen
DMBIAnalytics.detachScrollTracking()
```

### 4. User Types & Segments

```swift
// Set user type
DMBIAnalytics.setUserType(.subscriber) // .anonymous, .loggedIn, .subscriber, .premium

// Add user segments for cohort analysis
DMBIAnalytics.addUserSegment("sports_fan")
DMBIAnalytics.addUserSegment("premium_reader")

// Remove segment
DMBIAnalytics.removeUserSegment("sports_fan")

// Get all segments
let segments = DMBIAnalytics.getUserSegments()
```

### 5. Conversion Tracking

```swift
// Simple conversion
DMBIAnalytics.trackConversion(
    id: "sub_123",
    type: "subscription",
    value: 99.99,
    currency: "TRY"
)

// Detailed conversion with properties
DMBIAnalytics.trackConversion(
    Conversion(
        id: "purchase_456",
        type: "purchase",
        value: 149.99,
        currency: "TRY",
        properties: [
            "product_id": "prod_123",
            "category": "premium"
        ]
    )
)
```

### 6. Video Tracking

#### Manual Tracking

```swift
// Video started playing
DMBIAnalytics.trackVideoPlay(
    videoId: "vid123",
    title: "Video Title",
    duration: 180,
    position: 0
)

// Video progress (quartiles)
DMBIAnalytics.trackVideoProgress(
    videoId: "vid123",
    duration: 180,
    position: 45,
    percent: 25
)

// Video completed
DMBIAnalytics.trackVideoComplete(
    videoId: "vid123",
    duration: 180
)
```

#### Auto-Tracking with Player Wrappers

SDK includes wrappers for popular video players that automatically track play, pause, progress (25%, 50%, 75%, 100%), and complete events.

**AVPlayer (Native):**
```swift
import DMBIAnalytics

let player = AVPlayer(url: videoURL)
let wrapper = AVPlayerWrapper(player: player)
wrapper.attach(
    videoId: "vid123",
    title: "Video Title"
)

// When done:
wrapper.detach()
```

**YouTube Player:**
```swift
// Add pod: pod 'youtube-ios-player-helper'

import DMBIAnalytics

class VideoViewController: UIViewController {
    @IBOutlet weak var playerView: YTPlayerView!
    private var wrapper: YouTubePlayerWrapper?

    override func viewDidLoad() {
        super.viewDidLoad()
        wrapper = YouTubePlayerWrapper(playerView: playerView)
        wrapper?.attach(videoId: "dQw4w9WgXcQ", title: "Video Title")
        playerView.delegate = wrapper
        playerView.load(withVideoId: "dQw4w9WgXcQ")
    }
}
```

**Dailymotion Player:**
```swift
// Add pod: pod 'DailymotionPlayerSDK'

import DMBIAnalytics

let playerViewController = DMPlayerViewController()
let wrapper = DailymotionPlayerWrapper(player: playerViewController)
wrapper.attach(
    videoId: "x8abc123",
    title: "Video Title"
)
```

### 7. Push Notifications

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           didReceive response: UNNotificationResponse,
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    DMBIAnalytics.trackPushOpened(
        notificationId: userInfo["notification_id"] as? String,
        title: response.notification.request.content.title,
        campaign: userInfo["campaign"] as? String
    )

    completionHandler()
}
```

### 8. Engagement Metrics

```swift
// Get active time (excludes background)
let activeSeconds = DMBIAnalytics.getActiveTimeSeconds()

// Get heartbeat count
let pingCount = DMBIAnalytics.getPingCounter()

// Record user interaction (resets inactivity timer)
DMBIAnalytics.recordInteraction()
```

### 9. Custom Events

```swift
DMBIAnalytics.trackEvent(
    name: "article_share",
    properties: [
        "article_id": "12345",
        "share_platform": "twitter"
    ]
)
```

## Advanced Configuration

```swift
var config = DMBIConfiguration(
    siteId: "your-site-ios",
    endpoint: "https://realtime.dmbi.site/e"
)

// Customize settings
config.heartbeatInterval = 30           // Base heartbeat: 30 seconds
config.maxHeartbeatInterval = 120       // Max when inactive: 120 seconds
config.inactivityThreshold = 30         // Inactive after 30 seconds
config.batchSize = 10                   // Send events in batches of 10
config.flushInterval = 30               // Flush every 30 seconds
config.sessionTimeout = 30 * 60         // New session after 30 min background
config.debugLogging = true              // Enable debug logs

DMBIAnalytics.configure(with: config)
```

## SwiftUI Support

```swift
struct ArticleView: View {
    let article: Article

    var body: some View {
        ScrollView {
            // Your content
        }
        .onAppear {
            DMBIAnalytics.trackScreen(
                name: "ArticleDetail",
                url: "app://article/\(article.id)",
                title: article.title
            )
        }
        .onDisappear {
            DMBIAnalytics.detachScrollTracking()
        }
    }
}

// For scroll tracking in SwiftUI, use GeometryReader
struct ScrollTrackingView: View {
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    // Content
                }
                .background(
                    GeometryReader { contentGeo in
                        Color.clear.onChange(of: contentGeo.frame(in: .global).minY) { value in
                            let scrollOffset = -value
                            let contentHeight = contentGeo.size.height - geo.size.height
                            if contentHeight > 0 {
                                let percent = Int((scrollOffset / contentHeight) * 100)
                                DMBIAnalytics.reportScrollDepth(percent)
                            }
                        }
                    }
                )
            }
        }
    }
}
```

## Comparison with Competitors

| Feature | Chartbeat | Marfeel | DMBI SDK |
|---------|-----------|---------|----------|
| Heartbeat | 15s | 10s | 30s (dynamic) |
| Scroll tracking | ✅ | ✅ | ✅ |
| Active time | ? | ✅ | ✅ |
| Dynamic interval | ✅ | ❌ | ✅ |
| Conversions | ❌ | ✅ | ✅ |
| User segments | ✅ | ✅ | ✅ |
| Offline storage | ❌ | ❌ | ✅ |

## Requirements

- iOS 13.0+
- tvOS 13.0+
- watchOS 6.0+
- macOS 10.15+
- Swift 5.7+

## License

MIT License
