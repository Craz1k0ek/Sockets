#  WebSockets

This is a wrapper around the `URLSessionWebSocketTask` from Apple. The websockets are written using the new Swift concurrency in mind, providing an easy way to wait for method calls to the object.

### Create

```swift
let websocket = WebSocket(url: serverURL)

try await websocket.connect()
try await websocket.disconnect()
```
