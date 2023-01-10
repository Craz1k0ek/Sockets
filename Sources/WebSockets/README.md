#  WebSockets

This is a wrapper around the `URLSessionWebSocketTask` from Apple. The websockets are written using the new Swift concurrency in mind, providing an easy way interact with the object.

### Create

A socket can easily be created and interacted with.

```swift
let websocket = WebSocket(url: serverURL)

try await websocket.connect()
try await websocket.disconnect()
```

### Send

The websocket supports both `String` and `Data` to be sent. There are two functions that support these types, but one could also use the Apple provided `URLSessionWebSocketTask.Message` by calling the `open func send(_ message: URLSessionWebSocketTask.Message) async throws` function.

Sending a message on a closed socket will result in an `URLError(.cancelled)` error.

```swift
let websocket: WebSocket ...

// Text message
try await websocket.send("Hello World!")

// Binary message
let image: UIImage ...
if let imageBytes = image.pngData() {
    try await websocket.send(imageBytes)
}
```

### Reconnect
A socket can be reconnected. Conform spec, this will create a fresh socket, with the same parameters as previously provided.

```swift
let websocket: WebSocket ...

try await websocket.disconnect()
let reconnected = try await websocket.reconnect() 
```

Reconnecting will automatically connect the newly created socket. Calling reconnect on a connected socket will return the current socket, as reconnection is not required.

```swift
let websocket: WebSocket ...

try await websocket.connect()
let reconnected = try await websocket.reconnect()   // websocket == reconnected 
``` 

### Additional info

**Connecting a disconnected websocket will do nothing. This is similar behaviour to the existing task objects that Apple provides.**

```swift
let websocket: WebSocket ...

try await websocket.connect()
try await websocket.disconnect()
try await websocket.connect()       // This will not throw an error
```

**Disonnecting an unconnected or disconnected websocket will do nothing either.**

```swift
let websocket: WebSocket ...

try await websocket.disconnect()    // This will not throw an error

try await websocket.connect()
try await websocket.disconnect()
try await websocket.disconnect()    // Nor will this
```

**Deinitializing the websocket will also terminate outstanding continuations and tasks.**

```swift
let websocket: WebSocket? ...
websocket = nil                     // This will cancel outstanding tasks and continuations
```

**Errors are destructive**

Any error that is encountered while using the socket will result in a termination of the socket.
