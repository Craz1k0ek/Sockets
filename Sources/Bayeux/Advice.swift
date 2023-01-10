import Foundation

struct Advice: Codable {
    /// An integer representing the period of time, in seconds,
    /// for the server to delay responses to the `/meta/connect` channel.
    let timeout: TimeInterval?
    /// An integer representing the minimum period of time, in seconds,
    /// for a client to delay subsequent requests to the `/meta/connect` channel.
    /// A negative period indicates that the message should not be retried.
    let interval: TimeInterval?
    /// A string that indicates how the client should act in the case of a failure to connect.
    let reconnect: Reconnect?

    init(timeout: TimeInterval? = nil, interval: TimeInterval? = nil, reconnect: Reconnect? = nil) {
        self.timeout = timeout
        self.interval = interval
        self.reconnect = reconnect
    }

    private enum CodingKeys: String, CodingKey {
        case timeout, interval, reconnect
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let milliSeconds = try container.decodeIfPresent(Int.self, forKey: .timeout) {
            timeout = TimeInterval(milliSeconds / 1000)
        } else {
            timeout = nil
        }

        if let milliSeconds = try container.decodeIfPresent(Int.self, forKey: .interval) {
            interval = TimeInterval(milliSeconds / 1000)
        } else {
            interval = nil
        }

        reconnect = try container.decodeIfPresent(Bayeux.Advice.Reconnect.self, forKey: .reconnect)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let timeout {
            try container.encode(Int(timeout) * 1000, forKey: .timeout)
        }
        if let interval {
            try container.encode(Int(interval) * 1000, forKey: .timeout)
        }
        try container.encodeIfPresent(reconnect, forKey: .reconnect)
    }
}

extension Advice {
    enum Reconnect: String, Codable {
        /// Attempt to reconnect with a `/meta/connect` message after the interval,
        /// and with the same credentials.
        case retry
        /// The server has terminated any prior connection status and the client must
        /// reconnect with a `/meta/handshake` message.
        case handshake
        /// Indicates a hard failure for the connect attempt. A client must not automatically
        /// retry or handshake.
        case none
    }
}
