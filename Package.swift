import PackageDescription

let package = Package(
    name: "Edge",
    targets: [

    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reactive.git", majorVersion: 0, minor: 0),
        .Package(url: "https://github.com/SwiftOnEdge/IOStream.git", majorVersion: 0, minor: 0),
        .Package(url: "https://github.com/SwiftOnEdge/TCP.git", majorVersion: 0, minor: 0),
    ]
)
