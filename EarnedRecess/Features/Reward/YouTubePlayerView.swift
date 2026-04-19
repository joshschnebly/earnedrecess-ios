import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    @Binding var isPlaying: Bool
    var onPlayerReady: (() -> Void)? = nil
    var onVideoEnded: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []  // autoplay allowed

        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "playerBridge")
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator

        webView.loadHTMLString(htmlContent(for: videoId), baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Sync play/pause state from SwiftUI binding
        if isPlaying {
            webView.evaluateJavaScript("player.playVideo();", completionHandler: nil)
        } else {
            webView.evaluateJavaScript("player.pauseVideo();", completionHandler: nil)
        }
    }

    // MARK: - HTML template

    private func htmlContent(for videoId: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { background: #000; overflow: hidden; }
          #player { width: 100vw; height: 100vh; }
        </style>
        </head>
        <body>
        <div id="player"></div>
        <script>
          var tag = document.createElement('script');
          tag.src = "https://www.youtube.com/iframe_api";
          var firstScriptTag = document.getElementsByTagName('script')[0];
          firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

          var player;
          function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
              videoId: '\(videoId)',
              playerVars: {
                autoplay: 1,
                playsinline: 1,
                rel: 0,
                modestbranding: 1,
                controls: 1,
                fs: 0
              },
              events: {
                onReady: onPlayerReady,
                onStateChange: onPlayerStateChange
              }
            });
          }

          function onPlayerReady(event) {
            event.target.playVideo();
            window.webkit.messageHandlers.playerBridge.postMessage({ event: 'ready' });
          }

          function onPlayerStateChange(event) {
            var states = { 0: 'ended', 1: 'playing', 2: 'paused', 3: 'buffering' };
            var stateName = states[event.data] || 'unknown';
            window.webkit.messageHandlers.playerBridge.postMessage({ event: stateName });
          }
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubePlayerView

        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let event = body["event"] as? String else { return }

            DispatchQueue.main.async {
                switch event {
                case "ready":   self.parent.onPlayerReady?()
                case "ended":   self.parent.onVideoEnded?()
                case "playing": self.parent.isPlaying = true
                case "paused":  self.parent.isPlaying = false
                default: break
                }
            }
        }

        // Block navigation away from the video
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
