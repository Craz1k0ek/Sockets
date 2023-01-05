// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sockets",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "WebSockets", targets: ["WebSockets"])
    ],
    targets: [
        .target(name: "WebSockets"),
        .testTarget(name: "WebSocketsTests", dependencies: ["WebSockets"])
    ]
)
