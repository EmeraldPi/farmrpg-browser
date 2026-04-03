import AppKit
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {
    private(set) var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()

        // Allow inline media playback
        config.preferences.isElementFullscreenEnabled = true

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 720), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        // Set a custom user agent so FarmRPG serves mobile-friendly layout
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadFarmRPG()
    }

    func loadFarmRPG() {
        let url = URL(string: "https://farmrpg.com/")!
        webView.load(URLRequest(url: url))
    }

    func reload() {
        webView.reload()
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Open external links in system browser
        if let host = url.host?.lowercased(),
           !host.contains("farmrpg.com") && !host.contains("farmrpg."),
           navigationAction.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - WKUIDelegate

    // Handle target="_blank" links
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
