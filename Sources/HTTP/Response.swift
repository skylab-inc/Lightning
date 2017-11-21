//
//  Response.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

import Foundation

public struct Response: Serializable, HTTPMessage {

    public var version: Version
    public var status: Status
    public var rawHeaders: [String]
    public var body: Data
    public var storage: [String: Any] = [:]

    public var serialized: Data {
        var headerString = ""
        headerString += "HTTP/\(version.major).\(version.minor)"
        headerString += " \(status.code) \(status.reasonPhrase)"
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
            key == "set-cookie"
        }.map { $0.1 }
    }

    public init(
        version: Version = Version(major: 1, minor: 1),
        status: Status = .ok,
        rawHeaders: [String] = [],
        body: Data = Data()
    ) {
        self.version = version
        self.status = status
        self.body = body
        self.rawHeaders = Array([
            rawHeaders,
            [
                "Content-Length",
                "\(body.count)",
            ]
        ].joined())
    }

    public init(
        version: Version = Version(major: 1, minor: 1),
        status: Status
    ) {
        self.init(
            status: status,
            rawHeaders: ["Content-Length", "0"]
        )
    }

    public init(
        version: Version = Version(major: 1, minor: 1),
        status: Status = .ok,
        rawHeaders: [String] = [],
        json: Any
    ) throws {
        let body = try JSONSerialization.data(withJSONObject: json)
        let rawHeaders = Array([
            rawHeaders,
            [
                "Content-Type",
                "application/json",
                "Content-Length",
                "\(body.count)",
            ]
        ].joined())
        self.init(version: version, status: status, rawHeaders: rawHeaders, body: body)
    }

}
