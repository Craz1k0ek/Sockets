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
                        task = session.webSocketTask(with: url)
                        task?.delegate = self
                    } else {
                        task = taskSession.webSocketTask(with: url)
                    }
                    receive()
                    task?.resume()
                }
            }
        }
        self.connectTask = connectTask
        try await connectTask.value
    }

    private final func receive() {
        task?.receive() { [receive] response in
            switch response {
            case .success(let success):
                print(success)
                receive()
            case .failure(let failure):
                print(failure)
            }
        }
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        connectContinuation?.resume()
        objectWillChange.send()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            connectContinuation?.resume(throwing: error)
        }
        objectWillChange.send()
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error {
            connectContinuation?.resume(throwing: error)
        }
        objectWillChange.send()
    }
}
