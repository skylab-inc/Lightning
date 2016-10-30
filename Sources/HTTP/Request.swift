//
//  Request.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

import Foundation

public struct Request: Serializable {
    public var method: Method
    public var uri: URL
    public var version: Version
    public var rawHeaders: [String]
    public var body: [UInt8]
    public var storage: [String: Any]
    
    public var serialized: [UInt8] {
        var headerString = ""
        headerString += "\(method) \(uri) HTTP/\(version.major).\(version.minor)"
        headerString += "\n"
        
        let headerPairs: [(String, String)] = stride(from: 0, to: rawHeaders.count, by: 2).map {
            let chunk = rawHeaders[$0..<min($0 + 2, rawHeaders.count)]
            return (chunk.first!, chunk.last!)
        }
        
        for (name, value) in headerPairs {
            headerString += "\(name): \(value)"
            headerString += "\n"
        }
        
        headerString += "\n"
        return headerString.utf8 + body
    }

    public init(
        method: Method,
        uri: URL,
        version: Version = Version(major: 1, minor: 1),
        rawHeaders: [String] = [],
        body: [UInt8] = []
    ) {
        self.method = method
        self.uri = uri
        self.version = version
        self.rawHeaders = rawHeaders
        self.body = body
        self.storage = [:]
    }
    
}
