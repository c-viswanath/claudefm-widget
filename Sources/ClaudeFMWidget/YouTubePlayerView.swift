import SwiftUI
import WebKit

struct YouTubePlayerView: NSViewRepresentable {
    private let watchURL = URL(string: "https://www.youtube.com/watch?v=YmQ7jRgf4f0")!

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
            #movie_player .ytp-gradient-top { display: none !important; }
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

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        webView.load(URLRequest(url: watchURL))
        AppState.shared.webView = webView
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
