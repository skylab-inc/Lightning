//
//  Request.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

import Foundation

public class Request: Serializable, HTTPMessage {
    public var method: Method
    public var uri: URL
    public var version: Version
    public var rawHeaders: [String]
    public var body: Data
    public var storage: [String: Any]

    // Router dependent (refactor?)
    public var parameters: [String:String] = [:]

    public var serialized: Data {
        var headerString = ""
        headerString += "\(method) \(uri.absoluteString) HTTP/\(version.major).\(version.minor)"
        headerString += "\r\n"

        for (name, value) in rawHeaderPairs {
            headerString += "\(name): \(value)"
            headerString += "\r\n"
        }

        headerString += "\r\n"
        return headerString.utf8 + body
    }

    public var cookies: [String] {
        return lowercasedRawHeaderPairs.filter { (key, value) in
            key == "cookie"
        }.map { $0.1 }
    }

    public init(
        method: Method,
        uri: URL,
        version: Version = Version(major: 1, minor: 1),
        rawHeaders: [String] = [],
        body: Data = Data()
    ) {
        self.method = method
        self.uri = uri
        self.version = version
        self.rawHeaders = rawHeaders
        self.body = body
        self.storage = [:]
    }

}
