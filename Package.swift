import PackageDescription

let package = Package(
    name: "Edge",
    dependencies: [
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", majorVersion: 0),
        .Package(url: "../CHTTPParser", majorVersion: 0),
        //.Package(url: "https://github.com/antitypical/Result.git", majorVersion: 2)
    ]
)
