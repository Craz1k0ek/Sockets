import XCTest
@testable import WebSockets

final class SocketsTests: XCTestCase {
    var websocket: WebSocket!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = try XCTUnwrap(URL(string: "ws://localhost:8080/socket/test"))
        websocket = WebSocket(url: url)
    }

    func testMultipleConnectCalls() async throws {
        try await websocket.connect()
        try await websocket.connect()
        try await websocket.connect()
    }

    func testConnectDisconnectConnect() async throws {
        try await websocket.connect()
        try await websocket.disconnect()
        try await websocket.connect()
    }

    func testMultipleDisconnectCalls() async throws {
        try await websocket.connect()
        try await websocket.disconnect()
        try await websocket.disconnect()
        try await websocket.disconnect()
    }

    func testDisconnectWithoutConnect() async throws {
        try await websocket.disconnect()
    }

    func testSocketConnection() async throws {
        try await websocket.connect()
        XCTAssertTrue(websocket.isConnected)

        try await websocket.send("Hello, server!")
        try await websocket.send(Data("Hello world".utf8))

        try await websocket.disconnect()
        XCTAssertFalse(websocket.isConnected)
    }

    func testSessionInvalidation() async throws {
        try await websocket?.connect()
        try await websocket?.send("Hello World")

        do {
            for try await message in websocket!.messages {
                print(message)
                if case .string(let text) = message, text.starts(with: "5") {
                    websocket = nil
                }
            }
        } catch is CancellationError {}
    }

    func testReconnect() async throws {
        try await websocket.connect()
        try await websocket.disconnect()
        XCTAssertFalse(websocket.isConnected)

        let reconnected = try await websocket.reconnect()
        XCTAssertTrue(reconnected.isConnected)
        XCTAssertNotEqual(websocket, reconnected)
    }

    func testReconnectConnected() async throws {
        try await websocket.connect()

        let reconnected = try await websocket.reconnect()
        XCTAssertEqual(websocket, reconnected)
    }
}
