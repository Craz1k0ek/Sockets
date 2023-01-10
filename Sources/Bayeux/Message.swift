import Utility

public struct Message: Codable {
    /// The destination of the message, and in a response
    /// it specifies the source of the message.
    let channel: Channel
    /// Indicates the protocol version expected by the client or server.
    let version: String?
    /// Allows clients and servers to reveal the transports that are supported.
    let supportedConnectionTypes: [String]?
    /// The type of transport the client requires for communication.
    let connectionType: String?
    /// The advice message field provides a way for servers to inform clients of their
    /// preferred mode of client operation so that in conjunction with server-enforced limits,
    /// Bayeux implementations can prevent resource exhaustion and inelegant failure modes.
    let advice: Advice?

    /// The clientId message field uniquely identifies a client to the Bayeux server.
    let clientId: String?

    /// An alpha numeric identifier of the message.
    let id: String?
    /// The data message field is an arbitrary JSON encoded object that
    /// contains event information.
    let data: [String: Any]?
    /// The subscription message field specifies the channels the client
    /// wishes to subscribe to or unsubscribe from.
    let subscription: Channel?

    /// The boolean successful message field is used to indicate success or failure.
    let successful: Bool?
    /// Indicate the type of error that occurred when a request
    /// returns with a false successful message
    let error: String?

    /// Boolean value indicating whether or not this message indicates success.
    var isSuccessful: Bool {
        if let successful { return successful }
        return error == nil
    }

    init(channel: Channel, version: String? = "1.0", supportedConnectionTypes: [String]? = nil, connectionType: String? = nil, advice: Advice? = nil, clientId: String? = nil, id: String? = nil, data: [String: Any]? = nil, subscription: Channel? = nil) {
        self.channel = channel
        self.version = version
        self.supportedConnectionTypes = supportedConnectionTypes
        self.connectionType = connectionType
        self.advice = advice

        self.clientId = clientId

        self.id = id
        self.data = data
        self.subscription = subscription

        self.successful = nil
        self.error = nil
    }

    fileprivate enum JSONKeys: String, CodingKey {
        case channel, version, supportedConnectionTypes, connectionType, clientId, id, data, subscription, successful, error, advice
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONKeys.self)

        channel = try container.decode(Bayeux.Channel.self, forKey: .channel)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        supportedConnectionTypes = try container.decodeIfPresent([String].self, forKey: .supportedConnectionTypes)
        connectionType = try container.decodeIfPresent(String.self, forKey: .connectionType)
        advice = try container.decodeIfPresent(Advice.self, forKey: .advice)

        clientId = try container.decodeIfPresent(String.self, forKey: .clientId)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        data = try container.decodeIfPresent([String: Any].self, forKey: .data)
        subscription = try container.decodeIfPresent(Channel.self, forKey: .subscription)

        successful = try container.decodeIfPresent(Bool.self, forKey: .successful)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONKeys.self)

        try container.encode(channel, forKey: .channel)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(supportedConnectionTypes, forKey: .supportedConnectionTypes)
        try container.encodeIfPresent(connectionType, forKey: .connectionType)
        try container.encodeIfPresent(advice, forKey: .advice)

        try container.encodeIfPresent(clientId, forKey: .clientId)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(subscription, forKey: .subscription)

        try container.encodeIfPresent(successful, forKey: .successful)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
