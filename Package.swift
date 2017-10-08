import PackageDescription

let package = Package(
    name: "Edge",
    targets: [
        Target(name: "libc"),
        Target(name: "CHTTPParser"),
        Target(name: "POSIX", dependencies: ["libc"]),
        Target(name: "TCP", dependencies: ["POSIX", "IOStream", "libc"]),
        Target(name: "HTTP", dependencies: [ "POSIX", "IOStream", "TCP", "CHTTPParser"]),
        Target(name: "IOStream", dependencies: ["POSIX"]),
        Target(name: "RunLoop"),
        Target(name: "Edge", dependencies: ["TCP", "IOStream", "RunLoop", "HTTP", "Routing"]),
        Target(name: "Routing", dependencies: ["POSIX", "HTTP"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reflex.git", majorVersion: 0, minor: 6),
    ]
)
