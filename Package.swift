import PackageDescription

let package = Package(
    name: "Edge",
    targets: [
        Target(
            name: "POSIXExtensions"
        ),
        Target(
            name: "TCP",
            dependencies: ["POSIXExtensions", "IOStream"]
        ),
        Target(
            name: "HTTP",
            dependencies: [
                "POSIXExtensions",
                "IOStream",
                "TCP"
            ]
        ),
        Target(
            name: "IOStream",
            dependencies: ["POSIXExtensions"]
        ),
        Target(
            name: "RunLoop"
        ),
        Target(
            name: "Edge",
            dependencies: ["TCP", "IOStream", "RunLoop", "HTTP"]
        ),
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reflex.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/Zewo/POSIX.git", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/Zewo/Log.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/Zewo/URI.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/open-swift/S4.git", majorVersion: 0, minor: 8),
    ]
)
