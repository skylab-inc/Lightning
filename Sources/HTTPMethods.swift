//
//  HTTPMethods.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/28/16.
//
//

import Foundation


enum Method: String {
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case copy = "COPY"
    case lock = "LOCK"
    case mkcol = "MKCOL"
    case move = "MOVE"
    case propfind = "PROPFIND"
    case proppatch = "PROPPATCH"
    case search = "SEARCH"
    case unlock = "UNLOCK"
    case bind = "BIND"
    case rebind = "REBIND"
    case unbind = "UNBIND"
    case acl = "ACL"
    case report = "REPORT"
    case mkactivity = "MKACTIVITY"
    case checkout = "CHECKOUT"
    case merge = "MERGE"
    case mSearch = "M-SEARCH"
    case notify = "NOTIFY"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    case patch = "PATCH"
    case purge = "PURGE"
    case mkcalendar = "MKCALENDAR"
    case link = "LINK"
    case unlink = "UNLINK"
}

