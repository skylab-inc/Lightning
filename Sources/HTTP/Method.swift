//
//  Method.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/16/16.
//
//

import Foundation

public enum Method {
    case delete
    case get
    case head
    case post
    case put
    case connect
    case options
    case trace
    case patch
    case other(method: String)
}

extension Method {
    init(_ rawValue: String) {
        let method = rawValue.uppercased()
        switch method {
        case "DELETE":
            self = .delete
        case "GET":
            self = .get
        case "HEAD":
            self = .head
        case "POST":
            self = .post
        case "PUT":
            self = .put
        case "CONNECT":
            self = .connect
        case "OPTIONS":
            self = .options
        case "TRACE":
            self = .trace
        case "PATCH":
            self = .patch
        default:
            self = .other(method: method)
        }
    }
}

extension Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .delete:            return "DELETE"
        case .get:               return "GET"
        case .head:              return "HEAD"
        case .post:              return "POST"
        case .put:               return "PUT"
        case .connect:           return "CONNECT"
        case .options:           return "OPTIONS"
        case .trace:             return "TRACE"
        case .patch:             return "PATCH"
        case .other(let method): return method.uppercased()
        }
    }
}

extension Method: Hashable {
    public var hashValue: Int {
        switch self {
        case .delete:            return 0
        case .get:               return 1
        case .head:              return 2
        case .post:              return 3
        case .put:               return 4
        case .connect:           return 5
        case .options:           return 6
        case .trace:             return 7
        case .patch:             return 8
        case .other(let method): return 9 + method.hashValue
        }
    }
}

extension Method {
    init(code: Int) {
        switch code {
        case 00: self = .delete
        case 01: self = .get
        case 02: self = .head
        case 03: self = .post
        case 04: self = .put
        case 05: self = .connect
        case 06: self = .options
        case 07: self = .trace
        case 08: self = .other(method: "COPY")
        case 09: self = .other(method: "LOCK")
        case 10: self = .other(method: "MKCOL")
        case 11: self = .other(method: "MOVE")
        case 12: self = .other(method: "PROPFIND")
        case 13: self = .other(method: "PROPPATCH")
        case 14: self = .other(method: "SEARCH")
        case 15: self = .other(method: "UNLOCK")
        case 16: self = .other(method: "BIND")
        case 17: self = .other(method: "REBIND")
        case 18: self = .other(method: "UNBIND")
        case 19: self = .other(method: "ACL")
        case 20: self = .other(method: "REPORT")
        case 21: self = .other(method: "MKACTIVITY")
        case 22: self = .other(method: "CHECKOUT")
        case 23: self = .other(method: "MERGE")
        case 24: self = .other(method: "MSEARCH")
        case 25: self = .other(method: "NOTIFY")
        case 26: self = .other(method: "SUBSCRIBE")
        case 27: self = .other(method: "UNSUBSCRIBE")
        case 28: self = .patch
        case 29: self = .other(method: "PURGE")
        case 30: self = .other(method: "MKCALENDAR")
        case 31: self = .other(method: "LINK")
        case 32: self = .other(method: "UNLINK")
        default: self = .other(method: "UNKNOWN")
        }
    }
}

public func == (lhs: Method, rhs: Method) -> Bool {
    return lhs.description == rhs.description
}
