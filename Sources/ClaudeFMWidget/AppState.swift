import WebKit

/// Shared bridge between SwiftUI views and the WKWebView player.
class AppState {
    static let shared = AppState()
    weak var webView: WKWebView?

    func pauseVideo() {
        webView?.evaluateJavaScript("document.querySelector('video')?.pause()", completionHandler: nil)
    }

    func resumeVideo() {
        webView?.evaluateJavaScript("document.querySelector('video')?.play()", completionHandler: nil)
    }
}
