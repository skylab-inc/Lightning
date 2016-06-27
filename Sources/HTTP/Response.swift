//
//  Response.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

public struct Response {
    public var version: Version
    public var status: Status
    public var rawHeaders: [String]
    public var body: [UInt8]
    public var storage: [String: Any] = [:]
    
    public init(version: Version, status: Status, rawHeaders: [String], body: [UInt8]) {
        self.version = version
        self.status = status
        self.rawHeaders = rawHeaders
        self.body = body
    }
}
