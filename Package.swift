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
        .package(url: "https://github.com/skylab-inc/StreamKit.git", from: "0.7.0"),
    ],
    targets: [
        .target(name: "CHTTPParser"),
        .target(name: "POSIX"),
        .target(name: "TCP", dependencies: ["POSIX", "IOStream"]),
        .target(name: "HTTP", dependencies: [ "POSIX", "IOStream", "TCP", "CHTTPParser", "POSIX"]),
        .target(name: "IOStream", dependencies: ["POSIX", "StreamKit"]),
        .target(name: "Edge", dependencies: ["TCP", "IOStream", "HTTP"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
        .testTarget(name: "IOStreamTests", dependencies: ["IOStream"]),
        .testTarget(name: "TCPTests", dependencies: ["TCP"]),
        .testTarget(name: "RoutingTests", dependencies: ["HTTP"]),
    ]
)
