import Foundation

open class WebSocket: NSObject, ObservableObject {
    /// The URL of the websocket.
    public let url: URL
    /// The session that creates the websocket.
    /// - Note: Pre iOS 15 the websocket will create a new session to create
    /// the socket. The delegate of this session will be called where needed.
    public let session: URLSession

    /// Create the websocket.
    /// - Parameters:
    ///   - url: The URL to connect to.
    ///   - session: The session to create the session with.
    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }
}
