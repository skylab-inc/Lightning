// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Edge",
    products: [
        .library(
            name: "Edge",
            targets: [
                "Edge",
                "POSIX",
                "TCP",
                "HTTP",
                "IOStream",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/crossroadlabs/Regex.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/skylab-inc/PathToRegex.git", .branch("master")),
        .package(url: "https://github.com/skylab-inc/StreamKit.git", .branch("master")),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "4.5.0"),
    ],
    targets: [
        .target(name: "CHTTPParser"),
        .target(name: "POSIX"),
        .target(name: "TCP", dependencies: ["POSIX", "IOStream"]),
        .target(name: "HTTP", dependencies: [ "POSIX", "IOStream", "TCP", "CHTTPParser", "PromiseKit", "PathToRegex", "Regex"]),
        .target(name: "IOStream", dependencies: ["POSIX", "StreamKit"]),
        .target(name: "Edge", dependencies: ["TCP", "IOStream", "HTTP"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
        .testTarget(name: "IOStreamTests", dependencies: ["IOStream"]),
        .testTarget(name: "TCPTests", dependencies: ["TCP"]),
        .testTarget(name: "RoutingTests", dependencies: ["HTTP"]),
    ]
)
