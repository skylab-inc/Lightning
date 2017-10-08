import PackageDescription

let package = Package(
    name: "Edge",
    targets: [
        Target(name: "Libc"),
        Target(name: "CHTTPParser"),
        Target(name: "POSIX", dependencies: ["Libc"]),
        Target(name: "TCP", dependencies: ["POSIX", "IOStream", "Libc"]),
        Target(name: "HTTP", dependencies: [ "POSIX", "IOStream", "TCP", "CHTTPParser"]),
        Target(name: "IOStream", dependencies: ["POSIX"]),
        Target(name: "RunLoop"),
        Target(name: "Edge", dependencies: ["TCP", "IOStream", "RunLoop", "HTTP", "Routing"]),
        Target(name: "Routing", dependencies: ["POSIX", "HTTP"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Reflex.git", majorVersion: 0, minor: 5),
    ],
    swiftLanguageVersions: [3, 4]
)
