import XCTest
@testable import WebSockets

final class SocketsTests: XCTestCase {
    func testSocketConnection() async throws {
        let url = try XCTUnwrap(URL(string: "wss://demo.piesocket.com/v3/channel_xyz?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self"))
        var websocket: WebSocket? = WebSocket(url: url)

        try await websocket!.connect()
        XCTAssertTrue(websocket!.isConnected)
    }
}
