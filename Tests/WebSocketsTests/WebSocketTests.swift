import XCTest
@testable import WebSockets

final class SocketsTests: XCTestCase {
    var websocket: WebSocket!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = try XCTUnwrap(URL(string: "wss://socketsbay.com/wss/v2/1/demo/"))
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
}
