//
//  Request.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//

import Foundation

extension String {
    /// From https://github.com/IBM-Swift/Kitura/blob/bc0ac974229f92a7614c4e738343cfb663e2467e/Sources/Kitura/String%2BExtensions.swift
    /// Parses percent encoded string into query parameters
    var urlDecodedFieldValuePairs: [String : String] {
        var result: [String:String] = [:]

        for item in self.components(separatedBy: "&") {
            guard let range = item.range(of: "=") else {
                result[item] = nil
                continue
            }

            let key = String(item[..<range.lowerBound])
            let value = String(item[range.upperBound...])

            let valueReplacingPlus = value.replacingOccurrences(of: "+", with: " ")
            if let decodedValue = valueReplacingPlus.removingPercentEncoding {
                if let value = result[key] {
                    result[key] = "\(value),\(decodedValue)"
                } else {
                    result[key] = decodedValue
                }
            } else {
                result[key] = valueReplacingPlus
            }
        }

        return result
    }
}

public class Request: Serializable, HTTPMessage {
    public var method: Method
    public var uri: URL
    public var version: Version
    public var rawHeaders: [String]
    public var body: Data
    public var storage: [String: Any]
    public var queryParameters: [String:String] {
        return uri.query?.urlDecodedFieldValuePairs ?? [:]
    }
    public var createdAt: Date
    public var userData: [String: Any] = [:]

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
        self.createdAt = Date()
        self.storage = [:]
    }

}
