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
            name: "IOStream",
            dependencies: ["POSIXExtensions"]
        ),
        Target(
            name: "RunLoop"
        ),
        Target(
            name: "Edge",
            dependencies: ["TCP", "IOStream", "RunLoop"]
        ),
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reactive.git", majorVersion: 0, minor: 0),
        .Package(url: "https://github.com/Zewo/POSIX.git", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/Zewo/Log.git", majorVersion: 0, minor: 8)
    ]
)
