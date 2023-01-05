// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sockets",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Sockets", targets: ["Sockets"]),
    ],
    targets: [
        .target(name: "Sockets"),
        .testTarget(name: "SocketsTests", dependencies: ["Sockets"]),
    ]
)
