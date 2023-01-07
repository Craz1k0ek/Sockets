import XCTest
@testable import WebSockets

final class SocketsTests: XCTestCase {
    var websocket: WebSocket!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = try XCTUnwrap(URL(string: "ws://localhost:8080/socket/test"))
        websocket = WebSocket(url: url)
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

        for try await message in websocket!.messages {
            if case .string(let text) = message, text.starts(with: "5") {
                websocket = nil
            }
        }
    }
}
