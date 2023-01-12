import Foundation

open class WebSocket: NSObject, ObservableObject {
    /// The URL of the websocket.
    public let url: URL
    /// The session used to create the websocket task.
    public let session: URLSession

    /// The session used to create the websocket task.
    @available(iOS, deprecated: 15, message: "Set the URLSessionWebSocketTask.delegate instead of using a custom URLSession instance")
    private lazy var taskSession = URLSession(configuration: session.configuration, delegate: socketDelegate, delegateQueue: session.delegateQueue)

    /// The underlying websocket task.
    private var task: URLSessionWebSocketTask?
    /// The delegate wrapper of the socket.
    ///
    /// This wrapper is required to make sure the `URLSession` does
    /// correctly release the delegate.
    private lazy var socketDelegate = WebSocket.Delegate(delegate: self)

    /// An array of protocols to negotiate with the server.
    private var protocols = [String]()

    private var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Continuation?
    /// Messages received during the lifetime of the websocket.
    private(set) public lazy var messages: AsyncThrowingStream<URLSessionWebSocketTask.Message, Error> = AsyncThrowingStream(URLSessionWebSocketTask.Message.self) { [weak self] continuation in
        self?.messageContinuation = continuation
    }

    /// Boolean value indicating whether or not the websocket is connected.
    open var isConnected: Bool {
        guard let task else {
            return false
        }

        switch task.state {
        case .canceling, .completed:
            return false
        case .running:
            return true
        default:
            return task.closeCode == .invalid
        }
    }

    /// Create the websocket.
    /// - Parameters:
    ///   - url: The URL to connect to.
    ///   - session: The session to create the session with.
    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    deinit {
        task?.cancel(with: .goingAway, reason: nil)
        taskSession.invalidateAndCancel()

        connectContinuation?.resume(throwing: CancellationError())
        disconnectContinuation?.resume(throwing: CancellationError())
        messageContinuation?.finish(throwing: CancellationError())
    }

    private var connectTask: Task<Void, Error>?
    private var connectContinuation: CheckedContinuation<Void, Error>?

    /// Connect the websocket.
    /// - Parameter protocols: An array of protocols to negotiate with the server.
    open func connect(protocols: [String] = []) async throws {
        guard !isConnected else { return }

        if let connectTask {
            return try await connectTask.value
        }
        self.protocols = protocols

        let connectTask = Task {
            try await withCheckedThrowingContinuation { continuation in
                connectContinuation = continuation
                if #available(iOS 15, *) {
                    task = session.webSocketTask(with: url)
                    task?.delegate = socketDelegate
                } else {
                    task = taskSession.webSocketTask(with: url)
                }
                receive()
                task?.resume()
            }
        }
        self.connectTask = connectTask
        try await connectTask.value
    }

    private var disconnectTask: Task<Void, Error>?
    private var disconnectContinuation: CheckedContinuation<Void, Error>?

    /// Disconnect the websocket.
    /// - Parameters:
    ///   - code: The close code that indicates the reason for closing the connection.
    ///   - reason: Optional further information to explain the closing. The value of this parameter is defined by the endpoints, not by the standard.
    open func disconnect(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: Data? = nil) async throws {
        guard isConnected, let task else { return }

        if let disconnectTask {
            return try await disconnectTask.value
        }

        let disconnectTask = Task {
            try await withCheckedThrowingContinuation { continuation in
                disconnectContinuation = continuation
                task.cancel(with: code, reason: reason)
            }
        }
        self.disconnectTask = disconnectTask
        try await disconnectTask.value
    }

    /// Receive websocket messages.
    private final func receive() {
        task?.receive { [weak self] response in
            switch response {
            case .success(let message):
                self?.messageContinuation?.yield(message)
                self?.receive()
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    /// Send a websocket message over the websocket.
    /// - Parameter message: The message to send over the websocket.
    open func send(_ message: URLSessionWebSocketTask.Message) async throws {
        guard let task else { throw URLError(.cancelled) }
        try await task.send(message)
    }

    /// Send a textual message to the websocket.
    /// - Parameter text: The message to send over the websocket.
    open func send(_ text: String) async throws {
        try await send(.string(text))
    }

    /// Send a binary message to the websocket.
    /// - Parameter data: The message to send over the websocket.
    open func send(_ data: Data) async throws {
        try await send(.data(data))
    }

    /// Reconnect the websocket.
    /// - Note: Reconnection actually is creating a new websocket.
    /// - Returns: The reconnected websocket or `self` when the socket is still connected.
    public func reconnect() async throws -> WebSocket {
        guard !isConnected else { return self }

        if task == nil {
            try await connect(protocols: protocols)
            return self
        }

        let websocket = WebSocket(url: url, session: session)
        try await websocket.connect(protocols: protocols)
        return websocket
    }

    /// Handle errors and cancel tasks when one occured.
    /// - Parameter error: The error that occured.
    private final func handleError(_ error: Error) {
        connectContinuation?.resume(throwing: error)
        connectContinuation = nil

        disconnectContinuation?.resume(throwing: error)
        disconnectContinuation = nil

        task?.cancel(with: .abnormalClosure, reason: error.localizedDescription.data(using: .utf8))

        messageContinuation?.finish(throwing: error)
        messageContinuation = nil
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connectContinuation?.resume()
        connectContinuation = nil

        objectWillChange.send()

        if #unavailable(iOS 15) {
            (self.session.delegate as? URLSessionWebSocketDelegate)?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
        }
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        disconnectContinuation?.resume()
        disconnectContinuation = nil

        messageContinuation?.finish()
        messageContinuation = nil

        objectWillChange.send()

        if #unavailable(iOS 15) {
            (self.session.delegate as? URLSessionWebSocketDelegate)?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer { objectWillChange.send() }

        if let error {
            return handleError(error)
        }

        connectContinuation?.resume()
        connectContinuation = nil

        disconnectContinuation?.resume()
        disconnectContinuation = nil

        messageContinuation?.finish()
        messageContinuation = nil

        self.task = nil

        if #unavailable(iOS 15) {
            (self.session.delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
        }
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let delegate = session.delegate else {
            return completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
        delegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
    }
}
