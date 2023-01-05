import XCTest
@testable import WebSockets

final class SocketsTests: XCTestCase {
    var websocket: WebSocket!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = try XCTUnwrap(URL(string: "wss://demo.piesocket.com/v3/channel_xyz?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self"))
        websocket = WebSocket(url: url)
    }

    func testSocketConnection() async throws {
        try await websocket.connect()
        XCTAssertTrue(websocket.isConnected)

        try await websocket.disconnect()
        XCTAssertFalse(websocket.isConnected)
    }
}
