#if canImport(DailymotionPlayerSDK)
import Foundation
import UIKit
import DailymotionPlayerSDK

/// Wrapper for Dailymotion iOS Player that automatically tracks video analytics events.
///
/// This wrapper supports the new Dailymotion SDK with DMVideoDelegate pattern.
/// It automatically detects video changes (including auto-play) and tracks analytics accordingly.
///
/// Usage:
/// ```swift
/// // Create player
/// Dailymotion.createPlayer(
///     playerId: "YOUR_PLAYER_ID",
///     videoId: "x8abc123"
/// ) { result in
///     switch result {
///     case .success(let player):
///         self.wrapper = DailymotionPlayerWrapper(player: player, presentingViewController: self)
///         self.wrapper.attach(videoId: "x8abc123", title: "Video Title")
///         // Add player view to hierarchy
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
public class DailymotionPlayerWrapper: NSObject {

    // MARK: - Properties

    private weak var player: DMPlayerView?
    private weak var presentingViewController: UIViewController?
    private var videoId: String?
    private var videoTitle: String?
    private var videoDuration: Float?
    private var lastReportedQuartile: Int = 0
    private var hasTrackedImpression: Bool = false
    private var isPlaying: Bool = false
    private var currentPosition: Double = 0
    private var totalDuration: Double = 0

    // MARK: - Initialization

    /// Initialize the wrapper with a Dailymotion player and presenting view controller.
    ///
    /// - Parameters:
    ///   - player: The DMPlayerView instance
    ///   - presentingViewController: The view controller that will present fullscreen/ad views (required by DMPlayerDelegate)
    public init(player: DMPlayerView, presentingViewController: UIViewController) {
        self.player = player
        self.presentingViewController = presentingViewController
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
        resetTrackingState()

        player?.videoDelegate = self
        player?.playerDelegate = self
    }

    /// Detach analytics tracking from the player.
    public func detach() {
        videoId = nil
        videoTitle = nil
        player?.videoDelegate = nil
        player?.playerDelegate = nil
    }

    // MARK: - Video Change Detection

    /// Fetches current video state and detects if video has changed.
    /// Called on videoDidStart to handle auto-play scenarios.
    private func checkForVideoChange() {
        player?.getState { [weak self] state in
            guard let self = self,
                  let newVideoId = state?.videoId,
                  !newVideoId.isEmpty else { return }

            // Video has changed (auto-play or manual)
            if newVideoId != self.videoId {
                self.handleVideoChange(
                    newVideoId: newVideoId,
                    title: state?.videoTitle,
                    duration: state?.videoDuration.map { Float($0) }
                )
            }
        }
    }

    /// Handle video change (e.g., auto-play next video).
    private func handleVideoChange(newVideoId: String, title: String?, duration: Float?) {
        videoId = newVideoId
        videoTitle = title
        videoDuration = duration
        resetTrackingState()
    }

    private func resetTrackingState() {
        lastReportedQuartile = 0
        hasTrackedImpression = false
        isPlaying = false
        currentPosition = 0
        totalDuration = 0
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

// MARK: - DMVideoDelegate

extension DailymotionPlayerWrapper: DMVideoDelegate {

    public func videoDidStart(_ player: DMPlayerView) {
        // Check if this is a new video (auto-play scenario)
        checkForVideoChange()

        if !hasTrackedImpression {
            trackImpression()
            hasTrackedImpression = true
        }
    }

    public func videoDidEnd(_ player: DMPlayerView) {
        trackComplete()
        isPlaying = false
    }

    public func videoDidPlay(_ player: DMPlayerView) {
        if !isPlaying {
            trackPlay()
            isPlaying = true
        }
    }

    public func videoDidPause(_ player: DMPlayerView) {
        if isPlaying {
            trackPause()
            isPlaying = false
        }
    }

    public func video(_ player: DMPlayerView, didChangeTime time: Double) {
        currentPosition = time
        checkQuartileProgress()
    }

    public func video(_ player: DMPlayerView, didChangeDuration duration: Double) {
        totalDuration = duration
    }
}

// MARK: - DMPlayerDelegate

extension DailymotionPlayerWrapper: DMPlayerDelegate {

    // MARK: Required Methods

    public func player(_ player: DMPlayerView, openUrl url: URL) {
        // Open URL in Safari/default browser
        UIApplication.shared.open(url)
    }

    public func playerWillPresentFullscreenViewController(_ player: DMPlayerView) -> UIViewController {
        // Return the presenting view controller for fullscreen playback
        return presentingViewController ?? UIViewController()
    }

    public func playerWillPresentAdInParentViewController(_ player: DMPlayerView) -> UIViewController {
        // Return the presenting view controller for ad presentation
        return presentingViewController ?? UIViewController()
    }

    // MARK: Optional Methods

    public func playerDidStart(_ player: DMPlayerView) {
        // Player started
    }

    public func playerDidEnd(_ player: DMPlayerView) {
        // Player ended
    }

    public func player(_ player: DMPlayerView, didChangeVideo videoId: String?) {
        // New video loaded (including auto-play)
        checkForVideoChange()
    }

    public func player(_ player: DMPlayerView, didFailWithError error: Error) {
        // Handle error if needed
    }
}
#endif
