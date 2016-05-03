import PackageDescription

let package = Package(
    name: "Edge",
    dependencies: [
        .Package(url: "../CUV", majorVersion: 2, minor: 6)
    ]
)
