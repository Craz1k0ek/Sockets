import Foundation

open class WebSocket: NSObject, ObservableObject {
    /// The URL of the websocket.
    public let url: URL

    /// The session used to create the websocket task.
    private let session: URLSession
    /// The session used to create the websocket task.
    @available(iOS, deprecated: 15, message: "Set the URLSessionWebSocketTask.delegate instead of using a custom URLSession instance")
    private lazy var taskSession = URLSession(configuration: session.configuration, delegate: self, delegateQueue: session.delegateQueue)
    /// The underlying websocket task.
    private var task: URLSessionWebSocketTask?

    /// Boolean value indicating whether or not the websocket is connected.
    open var isConnected: Bool {
        guard let task else { return false }
        return task.closeCode == .invalid
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

        defer {
            self.connectContinuation = nil
            self.connectTask = nil
        }

        let connectTask = Task {
            if task == nil {
                try await withCheckedThrowingContinuation { continuation in
                    connectContinuation = continuation
                    if #available(iOS 15, *) {
                        task = session.webSocketTask(with: url, protocols: protocols)
                        task?.delegate = self
                    } else {
                        task = taskSession.webSocketTask(with: url, protocols: protocols)
                    }
                    receive()
                    task?.resume()
                }
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
        guard let task else { return }

        if let disconnectTask {
            return try await disconnectTask.value
        }

        defer {
            disconnectContinuation = nil
            disconnectTask = nil
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

    private final func receive() {
        task?.receive() { [handleError, receive] response in
            switch response {
            case .success(let message):
                receive()
            case .failure(let error):
                handleError(error)
            }
        }
    }

    /// Send a websocket message over the websocket.
    /// - Parameter message: The message to send over the websocket.
    private final func send(_ message: URLSessionWebSocketTask.Message) async throws {
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

    /// Handle errors and cancel tasks when one occured.
    /// - Parameter error: The optional error that occured.
    private final func handleError(_ error: Error?) {
        guard let error else { return }

        connectContinuation?.resume(throwing: error)
        disconnectContinuation?.resume(throwing: error)

        if [ECONNRESET, ENOTCONN, ETIMEDOUT].contains(Int32((error as NSError).code)) {
            task?.cancel(with: .abnormalClosure, reason: nil)
        }

        task?.cancel()
        task = nil
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connectContinuation?.resume()
        objectWillChange.send()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        disconnectContinuation?.resume()
        self.task = nil
        objectWillChange.send()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        handleError(error)
        objectWillChange.send()
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        handleError(error)
        objectWillChange.send()
    }
}
