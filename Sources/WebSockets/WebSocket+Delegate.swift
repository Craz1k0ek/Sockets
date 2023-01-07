import Foundation

extension WebSocket {
    /// A `URLSessionWebSocketDelegate` wrapper, required to accomodate
    /// the release of the `URLSession` delegate.
    class Delegate: NSObject, URLSessionWebSocketDelegate {
        /// The underlying delegate.
        private weak var delegate: URLSessionWebSocketDelegate?

        /// Create the delegate from the actual delegate.
        /// - Parameter delegate: The actual delegate.
        init(delegate: URLSessionWebSocketDelegate) {
            self.delegate = delegate
        }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            delegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
        }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            delegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
        }

        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            delegate?.urlSession?(session, didBecomeInvalidWithError: error)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            delegate?.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }
}
