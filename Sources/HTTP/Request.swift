public struct Request {
    public var method: Method
    public var uri: URI
    public var version: Version
    public var headers: [String: String]
    public var body: [UInt8]
    public var storage: [String: Any]

    public init(method: Method, uri: URI, version: Version, headers: [String: String], body: [UInt8]) {
        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.storage = [:]
    }
}
