public enum Channel: Codable, Hashable, RawRepresentable {
    /// The handshake meta channel.
    case handshake
    /// The connect meta channel.
    case connect
    /// The disconnect meta channel.
    case disconnect
    /// The subscribe meta channel.
    case subscribe
    /// The unsubscribe meta channel.
    case unsubscribe
    /// A user defined channel.
    case custom(String)

    public init?(rawValue: String) {
        switch rawValue {
        case "/meta/handshake": self = .handshake
        case "/meta/connect": self = .connect
        case "/meta/disconnect": self = .disconnect
        case "/meta/subscribe": self = .subscribe
        case "/meta/unsubscribe": self = .unsubscribe
        default: self = .custom(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .handshake: return "/meta/handshake"
        case .connect: return "/meta/connect"
        case .disconnect: return "/meta/disconnect"
        case .subscribe: return "/meta/subscribe"
        case .unsubscribe: return "/meta/unsubscribe"
        case .custom(let channel): return channel
        }
    }
}
