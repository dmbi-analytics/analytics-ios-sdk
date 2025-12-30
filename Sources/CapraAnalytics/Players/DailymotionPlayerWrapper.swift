#if canImport(DailymotionPlayerSDK)
import Foundation
import DailymotionPlayerSDK

/// Wrapper for Dailymotion iOS Player that automatically tracks video analytics events.
///
/// Usage:
/// ```swift
/// let playerViewController = DMPlayerViewController()
/// let wrapper = DailymotionPlayerWrapper(player: playerViewController)
/// wrapper.attach(
///     videoId: "x8abc123",
///     title: "Video Title",
///     duration: 180
/// )
///
/// // Add player to view hierarchy
/// addChild(playerViewController)
/// view.addSubview(playerViewController.view)
/// playerViewController.didMove(toParent: self)
///
/// // Load video
/// playerViewController.load(videoId: "x8abc123")
/// ```
public class DailymotionPlayerWrapper: NSObject, DMPlayerViewControllerDelegate {

    private let player: DMPlayerViewController
    private var videoId: String?
    private var videoTitle: String?
    private var videoDuration: Float?
    private var lastReportedQuartile: Int = 0
    private var hasTrackedImpression: Bool = false
    private var isPlaying: Bool = false
    private var currentPosition: Double = 0
    private var totalDuration: Double = 0

    public init(player: DMPlayerViewController) {
        self.player = player
        super.init()
    }

    /// Attach analytics tracking to the Dailymotion player.
    ///
    /// - Parameters:
    ///   - videoId: Dailymotion video ID
    ///   - title: Optional video title
    ///   - duration: Optional video duration in seconds
    public func attach(videoId: String, title: String? = nil, duration: Float? = nil) {
        self.videoId = videoId
        self.videoTitle = title
        self.videoDuration = duration
        self.lastReportedQuartile = 0
        self.hasTrackedImpression = false
        self.isPlaying = false

        player.delegate = self
    }

    /// Detach analytics tracking from the player.
    public func detach() {
        videoId = nil
        videoTitle = nil
    }

    // MARK: - DMPlayerViewControllerDelegate

    public func player(_ player: DMPlayerViewController, didReceiveEvent event: PlayerEvent) {
        switch event {
        case .videoStart:
            if !hasTrackedImpression {
                trackImpression()
                hasTrackedImpression = true
            }

        case .play:
            if !isPlaying {
                trackPlay()
                isPlaying = true
            }

        case .pause:
            if isPlaying {
                trackPause()
                isPlaying = false
            }

        case .videoEnd:
            trackComplete()
            isPlaying = false

        case .timeUpdate(let time):
            currentPosition = time
            checkQuartileProgress()

        case .durationChange(let duration):
            totalDuration = duration

        default:
            break
        }
    }

    public func player(_ player: DMPlayerViewController, didFailWithError error: Error) {
        // Handle error if needed
    }

    // MARK: - Tracking Methods

    private func trackImpression() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? Float(totalDuration)

        CapraAnalytics.trackVideoImpression(
            videoId: id,
            title: videoTitle,
            duration: duration > 0 ? duration : nil
        )
    }

    private func trackPlay() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? Float(totalDuration)

        CapraAnalytics.trackVideoPlay(
            videoId: id,
            title: videoTitle,
            duration: duration > 0 ? duration : nil,
            position: Float(currentPosition)
        )
    }

    private func trackPause() {
        guard let id = videoId else { return }
        let percent = calculatePercent()

        CapraAnalytics.trackVideoPause(
            videoId: id,
            position: Float(currentPosition),
            percent: percent
        )
    }

    private func trackComplete() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? Float(totalDuration)

        CapraAnalytics.trackVideoComplete(
            videoId: id,
            duration: duration > 0 ? duration : nil
        )
    }

    private func trackQuartile(_ percent: Int) {
        guard let id = videoId else { return }
        let duration = videoDuration ?? Float(totalDuration)

        CapraAnalytics.trackVideoProgress(
            videoId: id,
            duration: duration > 0 ? duration : nil,
            position: Float(currentPosition),
            percent: percent
        )
    }

    // MARK: - Helper Methods

    private func calculatePercent() -> Int {
        let duration = videoDuration ?? Float(totalDuration)
        guard duration > 0 else { return 0 }
        return Int((Float(currentPosition) / duration) * 100)
    }

    private func checkQuartileProgress() {
        let percent = calculatePercent()
        let quartiles = [25, 50, 75, 100]

        for quartile in quartiles {
            if percent >= quartile && lastReportedQuartile < quartile {
                trackQuartile(quartile)
                lastReportedQuartile = quartile
            }
        }
    }
}
#endif
