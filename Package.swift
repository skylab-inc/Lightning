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
            dependencies: ["TCP", "IOStream", "RunLoop", "HTTP", "Drift"]
        ),
        Target(
            name: "Drift",
            dependencies: ["POSIXExtensions", "HTTP"]
        ),
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reflex.git", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/Zewo/POSIX.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/CHTTPParser.git", majorVersion: 0, minor: 14),
    ]
)
