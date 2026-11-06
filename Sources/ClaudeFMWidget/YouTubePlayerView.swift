import SwiftUI
import WebKit

struct YouTubePlayerView: NSViewRepresentable {
    // Current Claude FM stream. 24/7 streams get restarted under new video IDs,
    // and the old one goes private — so if this one stops playing we fall back
    // to the channel's /live URL, which always points at whatever is live now.
    private let watchURL = URL(string: "https://www.youtube.com/watch?v=tRsQsTMvPNg")!
    private static let fallbackURL = URL(string: "https://www.youtube.com/@claude/live")!
    private static let statusHandler = "streamStatus"
    private static let stateHandler = "playerState"

    // Reports play/pause/volume changes so the bar's controls match the player
    // and AppState can undo volume changes YouTube makes on its own. Media
    // events don't bubble, so listen in the capture phase on the document.
    private let stateScript = """
    (function() {
        var first = true;
        function report(v) {
            var p = document.getElementById('movie_player');
            var api = p && typeof p.getVolume === 'function' && typeof p.isMuted === 'function';
            window.webkit.messageHandlers.playerState.postMessage({
                paused: v.paused,
                volume: api ? p.getVolume() / 100 : v.volume,
                muted:  api ? p.isMuted() : v.muted,
                first:  first && !v.paused
            });
            if (!v.paused) first = false;
        }
        ['playing', 'pause', 'volumechange'].forEach(function(type) {
            document.addEventListener(type, function(e) {
                if (e.target instanceof HTMLVideoElement) report(e.target);
            }, true);
        });
    })();
    """

    // Reports the player's playability ("OK", "LOGIN_REQUIRED" for private,
    // "ERROR" for removed, …) back to Swift once the watch page has loaded.
    private let statusScript = """
    (function() {
        var r = window.ytInitialPlayerResponse;
        var s = r && r.playabilityStatus && r.playabilityStatus.status;
        if (s) { window.webkit.messageHandlers.streamStatus.postMessage(s); }
    })();
    """

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?
        private var didFallBack = false

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == YouTubePlayerView.stateHandler {
                AppState.shared.handlePlayerState(message.body)
                return
            }
            guard let status = message.body as? String, status != "OK",
                  !didFallBack else { return }
            didFallBack = true
            webView?.load(URLRequest(url: YouTubePlayerView.fallbackURL))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private let cleanupScript = """
    (function() {
        var style = document.createElement('style');
        style.textContent = `
            #masthead-container, #masthead,
            ytd-miniplayer, #chat, #chat-container,
            ytd-watch-next-secondary-results-renderer,
            #secondary, #related,
            #below, #comments,
            ytd-engagement-panel-section-list-renderer,
            tp-yt-paper-dialog, .ytp-endscreen-content,
            .ytp-cards-teaser, .ytp-cards-button,
            .ytp-watermark, .ytp-chrome-top,
            .iv-branding, .annotation,
            #movie_player .ytp-gradient-top,
            /* YouTube's own controls: the video is a drag handle, and the bar has play/pause + volume */
            .ytp-chrome-bottom, .ytp-gradient-bottom,
            .ytp-large-play-button, .ytp-pause-overlay { display: none !important; }
            html, body { overflow: hidden !important; background: #000 !important; }
            #primary, #primary-inner, ytd-watch-flexy,
            #player-container-outer, #player-container,
            #player-container-inner, #player, #player-wrap,
            .html5-video-container, video {
                width: 100% !important;
                height: 100% !important;
                max-width: 100% !important;
            }
            ytd-app { overflow: hidden !important; }
        `;
        document.head.appendChild(style);

        // Disable right-click context menu inside the page
        document.addEventListener('contextmenu', function(e) { e.preventDefault(); }, true);
    })();
    """

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []

        let userScript = WKUserScript(
            source: cleanupScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(userScript)
        config.userContentController.addUserScript(WKUserScript(
            source: statusScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))
        config.userContentController.add(context.coordinator, name: Self.statusHandler)
        config.userContentController.addUserScript(WKUserScript(
            source: stateScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        config.userContentController.add(context.coordinator, name: Self.stateHandler)

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        context.coordinator.webView = webView
        webView.load(URLRequest(url: watchURL))
        AppState.shared.webView = webView
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
