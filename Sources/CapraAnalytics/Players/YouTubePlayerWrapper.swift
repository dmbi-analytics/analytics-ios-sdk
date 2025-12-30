#if canImport(YouTubeiOSPlayerHelper)
import Foundation
import YouTubeiOSPlayerHelper

/// Wrapper for YouTube iOS Player that automatically tracks video analytics events.
///
/// Usage:
/// ```swift
/// class VideoViewController: UIViewController, YTPlayerViewDelegate {
///     @IBOutlet weak var playerView: YTPlayerView!
///     private var wrapper: YouTubePlayerWrapper?
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         wrapper = YouTubePlayerWrapper(playerView: playerView)
///         wrapper?.attach(videoId: "dQw4w9WgXcQ", title: "Video Title")
///         playerView.delegate = wrapper
///         playerView.load(withVideoId: "dQw4w9WgXcQ")
///     }
/// }
/// ```
public class YouTubePlayerWrapper: NSObject, YTPlayerViewDelegate {

    private let playerView: YTPlayerView
    private var videoId: String?
    private var videoTitle: String?
    private var videoDuration: Float = 0
    private var lastReportedQuartile: Int = 0
    private var hasTrackedImpression: Bool = false
    private var currentPosition: Float = 0

    public init(playerView: YTPlayerView) {
        self.playerView = playerView
        super.init()
    }

    /// Attach analytics tracking to the YouTube player.
    ///
    /// - Parameters:
    ///   - videoId: YouTube video ID
    ///   - title: Optional video title
    public func attach(videoId: String, title: String? = nil) {
        self.videoId = videoId
        self.videoTitle = title
        self.lastReportedQuartile = 0
        self.hasTrackedImpression = false

        playerView.delegate = self
    }

    /// Detach analytics tracking from the player.
    public func detach() {
        videoId = nil
        videoTitle = nil
    }

    // MARK: - YTPlayerViewDelegate

    public func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        if !hasTrackedImpression {
            trackImpression()
            hasTrackedImpression = true
        }

        // Get video duration
        playerView.duration { [weak self] duration, error in
            if error == nil {
                self?.videoDuration = duration
            }
        }
    }

    public func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .playing:
            trackPlay()
        case .paused:
            trackPause()
        case .ended:
            trackComplete()
        default:
            break
        }
    }

    public func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        currentPosition = playTime
        checkQuartileProgress()
    }

    // MARK: - Tracking Methods

    private func trackImpression() {
        guard let id = videoId else { return }

        CapraAnalytics.trackVideoImpression(
            videoId: id,
            title: videoTitle,
            duration: videoDuration > 0 ? videoDuration : nil
        )
    }

    private func trackPlay() {
        guard let id = videoId else { return }

        CapraAnalytics.trackVideoPlay(
            videoId: id,
            title: videoTitle,
            duration: videoDuration > 0 ? videoDuration : nil,
            position: currentPosition
        )
    }

    private func trackPause() {
        guard let id = videoId else { return }
        let percent = calculatePercent()

        CapraAnalytics.trackVideoPause(
            videoId: id,
            position: currentPosition,
            percent: percent
        )
    }

    private func trackComplete() {
        guard let id = videoId else { return }

        CapraAnalytics.trackVideoComplete(
            videoId: id,
            duration: videoDuration > 0 ? videoDuration : nil
        )
    }

    private func trackQuartile(_ percent: Int) {
        guard let id = videoId else { return }

        CapraAnalytics.trackVideoProgress(
            videoId: id,
            duration: videoDuration > 0 ? videoDuration : nil,
            position: currentPosition,
            percent: percent
        )
    }

    // MARK: - Helper Methods

    private func calculatePercent() -> Int {
        guard videoDuration > 0 else { return 0 }
        return Int((currentPosition / videoDuration) * 100)
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
