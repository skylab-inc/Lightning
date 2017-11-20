//
//  Message.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation

public protocol HTTPMessage {
    var version: Version { get set }
    var rawHeaders: [String] { get set }
    var headers: [String:String] { get }
    var cookies: [String] { get }
    var body: Data { get set }
}

public extension HTTPMessage {

    /// Groups the `rawHeaders` into key-value pairs. If there is an odd number
    /// of `rawHeaders`, the last value will be discarded.
    var rawHeaderPairs: [(String, String)] {
        return stride(from: 0, to: self.rawHeaders.count, by: 2).flatMap {
            let chunk = rawHeaders[$0..<min($0 + 2, rawHeaders.count)]
            if let first = chunk.first, let last = chunk.last {
                return (first, last)
            }
            return nil
        }
    }

    /// The same as `rawHeaderPairs` with the key lowercased.
    var lowercasedRawHeaderPairs: [(String, String)] {
        return rawHeaderPairs.map { ($0.0.lowercased(), $0.1) }
    }

    /// Duplicates are handled in a way very similar to the way they are handled
    /// by Node.js. Which is to say that duplicates in the raw headers are handled as follows.
    ///
    /// * Duplicates of age, authorization, content-length, content-type, etag, expires, from, 
    /// host, if-modified-since, if-unmodified-since, last-modified, location, max-forwards, 
    /// proxy-authorization, referer, retry-after, or user-agent are discarded.
    /// * set-cookie is *excluded* from the formatted headers are handled by the request and
    /// response. The cookies field on the Request and Response objects can be users to get
    /// and set the cookies.
    /// * For all other headers, the values are joined together with ', '.
    ///
    /// The rawHeaders are processed from the 0th index forward.
    var headers: [String:String] {
        get {
            var headers: [String:String] = [:]
            let discardable = Set([
                "age",
                "authorization",
                "content-length",
                "content-type",
                "etag",
                "expires",
                "from",
                "host",
                "if-modified-since",
                "if-unmodified-since",
                "last-modified",
                "location",
                "max-forwards",
                "proxy-authorization",
                "referer",
                "retry-after",
                "user-agent"
            ])
            let cookies = Set([
                "set-cookie",
                "cookie"
            ])
            for (key, value) in lowercasedRawHeaderPairs {
                guard !cookies.contains(key) else {
                    continue
                }
                if let currentValue = headers[key] {
                    if discardable.contains(key) {
                        headers[key] = value
                    } else {
                        headers[key] = [currentValue, value].joined(separator: ", ")
                    }
                } else {
                    headers[key] = value
                }
            }
            return headers
        }
    }

}
