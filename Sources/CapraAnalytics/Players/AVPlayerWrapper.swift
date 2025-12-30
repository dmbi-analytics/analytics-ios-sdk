import Foundation
import AVFoundation

/// Wrapper for AVPlayer that automatically tracks video analytics events.
///
/// Usage:
/// ```swift
/// let player = AVPlayer(url: videoURL)
/// let wrapper = AVPlayerWrapper(player: player)
/// wrapper.attach(
///     videoId: "video-123",
///     title: "My Video Title",
///     duration: 180 // optional, auto-detected if not provided
/// )
///
/// // When done:
/// wrapper.detach()
/// ```
public class AVPlayerWrapper {

    private let player: AVPlayer
    private var videoId: String?
    private var videoTitle: String?
    private var videoDuration: Float?
    private var lastReportedQuartile: Int = 0
    private var hasTrackedImpression: Bool = false
    private var isPlaying: Bool = false

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?

    public init(player: AVPlayer) {
        self.player = player
    }

    /// Attach analytics tracking to the player.
    ///
    /// - Parameters:
    ///   - videoId: Unique identifier for the video
    ///   - title: Optional video title
    ///   - duration: Optional video duration in seconds (auto-detected if not provided)
    public func attach(videoId: String, title: String? = nil, duration: Float? = nil) {
        self.videoId = videoId
        self.videoTitle = title
        self.videoDuration = duration
        self.lastReportedQuartile = 0
        self.hasTrackedImpression = false
        self.isPlaying = false

        setupObservers()
    }

    /// Detach analytics tracking from the player.
    /// Call this when the player is being released.
    public func detach() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil

        videoId = nil
        videoTitle = nil
    }

    deinit {
        detach()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe player status for ready state
        statusObserver = player.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .readyToPlay {
                self?.onPlayerReady()
            }
        }

        // Observe rate changes for play/pause
        rateObserver = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            if player.rate > 0 {
                self?.onPlay()
            } else {
                self?.onPause()
            }
        }

        // Observe playback progress
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.onTimeUpdate(time: time)
        }

        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPlaybackEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    private func onPlayerReady() {
        if !hasTrackedImpression {
            trackImpression()
            hasTrackedImpression = true
        }
    }

    private func onPlay() {
        if !isPlaying {
            trackPlay()
            isPlaying = true
        }
    }

    private func onPause() {
        if isPlaying {
            trackPause()
            isPlaying = false
        }
    }

    private func onTimeUpdate(time: CMTime) {
        checkQuartileProgress()
    }

    @objc private func onPlaybackEnd() {
        trackComplete()
        isPlaying = false
    }

    // MARK: - Tracking Methods

    private func trackImpression() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? getDuration()

        CapraAnalytics.trackVideoImpression(
            videoId: id,
            title: videoTitle,
            duration: duration
        )
    }

    private func trackPlay() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? getDuration()
        let position = getCurrentPosition()

        CapraAnalytics.trackVideoPlay(
            videoId: id,
            title: videoTitle,
            duration: duration,
            position: position
        )
    }

    private func trackPause() {
        guard let id = videoId else { return }
        let position = getCurrentPosition()
        let percent = calculatePercent()

        CapraAnalytics.trackVideoPause(
            videoId: id,
            position: position,
            percent: percent
        )
    }

    private func trackComplete() {
        guard let id = videoId else { return }
        let duration = videoDuration ?? getDuration()

        CapraAnalytics.trackVideoComplete(
            videoId: id,
            duration: duration
        )
    }

    private func trackQuartile(_ percent: Int) {
        guard let id = videoId else { return }
        let duration = videoDuration ?? getDuration()
        let position = getCurrentPosition()

        CapraAnalytics.trackVideoProgress(
            videoId: id,
            duration: duration,
            position: position,
            percent: percent
        )
    }

    // MARK: - Helper Methods

    private func getDuration() -> Float? {
        guard let item = player.currentItem else { return nil }
        let duration = item.duration
        guard duration.isNumeric else { return nil }
        return Float(CMTimeGetSeconds(duration))
    }

    private func getCurrentPosition() -> Float {
        return Float(CMTimeGetSeconds(player.currentTime()))
    }

    private func calculatePercent() -> Int {
        guard let duration = videoDuration ?? getDuration(), duration > 0 else { return 0 }
        let position = getCurrentPosition()
        return Int((position / duration) * 100)
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
