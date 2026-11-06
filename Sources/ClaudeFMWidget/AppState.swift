import Foundation
import WebKit

/// Shared bridge between SwiftUI views and the WKWebView player.
///
/// Controls go through YouTube's own player API (`#movie_player`) rather than
/// the raw <video> element, so YouTube's internal volume/quality state stays in
/// sync with what the widget shows. Player events flow back in through
/// `handlePlayerState`, posted by the script in `YouTubePlayerView`.
final class AppState: ObservableObject {
    static let shared = AppState()
    weak var webView: WKWebView?

    @Published private(set) var isPlaying = false
    @Published private(set) var volume: Double      // 0…1
    @Published private(set) var isMuted: Bool
    @Published private(set) var isMini: Bool

    private enum Key {
        static let volume = "volume"
        static let muted  = "muted"
        static let mini   = "miniMode"
    }
    private let defaults = UserDefaults.standard

    private init() {
        volume  = defaults.object(forKey: Key.volume) as? Double ?? 1
        isMuted = defaults.bool(forKey: Key.muted)
        isMini  = defaults.bool(forKey: Key.mini)
    }

    // MARK: - Controls

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    /// Resumes at the live edge — it's a radio, so don't replay what was missed.
    func play() {
        run("""
        if (p && p.playVideo) { if (p.seekToLiveHead) p.seekToLiveHead(); p.playVideo(); }
        else if (v) { v.play(); }
        """)
    }

    func pause() {
        run("if (p && p.pauseVideo) p.pauseVideo(); else if (v) v.pause();")
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0), 1)
        defaults.set(volume, forKey: Key.volume)
        if isMuted && volume > 0 { setMuted(false) }
        applyVolume()
    }

    func toggleMute() {
        if isMuted && volume == 0 {
            setVolume(0.5)          // unmuting at 0 would stay silent; this also unmutes
        } else {
            setMuted(!isMuted)
        }
    }

    /// Mini mode hides the video, so drop to the lowest quality to save
    /// bandwidth and battery; "auto" restores YouTube's normal choice.
    func setMini(_ mini: Bool) {
        isMini = mini
        defaults.set(mini, forKey: Key.mini)
        applyQuality()
    }

    // MARK: - Player events (from the page)

    func handlePlayerState(_ body: Any) {
        guard let info = body as? [String: Any] else { return }
        if let paused = info["paused"] as? Bool { isPlaying = !paused }

        // A fresh page started playing: match quality to the current mode.
        if info["first"] as? Bool == true { applyQuality() }

        // The bar is the only volume control (YouTube's own controls are
        // hidden), so any other change is YouTube restoring its stored
        // volume during startup — put the user's setting back.
        if let v = info["volume"] as? Double, abs(v - volume) > 0.005 { applyVolume() }
        if let m = info["muted"] as? Bool, m != isMuted { applyMuted() }
    }

    // MARK: - Private

    private func setMuted(_ muted: Bool) {
        isMuted = muted
        defaults.set(muted, forKey: Key.muted)
        applyMuted()
    }

    private func applyMuted() {
        run("if (p && p.mute) { \(isMuted) ? p.mute() : p.unMute(); } else if (v) { v.muted = \(isMuted); }")
    }

    private func applyVolume() {
        let percent = Int((volume * 100).rounded())
        run("if (p && p.setVolume) p.setVolume(\(percent)); else if (v) v.volume = \(volume);")
    }

    private func applyQuality() {
        let quality = isMini ? "tiny" : "auto"
        run("if (p && p.setPlaybackQualityRange) p.setPlaybackQualityRange('\(quality)', '\(quality)');")
    }

    /// Runs `body` with `p` bound to YouTube's player element and `v` to the
    /// <video>; both may be null while the page is still loading.
    private func run(_ body: String) {
        webView?.evaluateJavaScript("""
        (function() {
            var p = document.getElementById('movie_player');
            var v = document.querySelector('video');
            \(body)
        })();
        """, completionHandler: nil)
    }
}
