//
//  Request.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

import S4

public struct Request {
    public var method: S4.Method
    public var uri: String
    public var version: Version
    public var rawHeaders: [String]
    public var body: [UInt8]
    public var storage: [String: Any]

    public init(method: S4.Method, uri: String, version: Version, rawHeaders: [String], body: [UInt8]) {
        self.method = method
        self.uri = uri
        self.version = version
        self.rawHeaders = rawHeaders
        self.body = body
        self.storage = [:]
    }
}
