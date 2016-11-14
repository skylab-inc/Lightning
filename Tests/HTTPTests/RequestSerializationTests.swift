//
//  RequestSerializationTests.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation
import XCTest
@testable import HTTP

class RequestSerializationTests: XCTestCase {

    func testBasicSerialization() {
        let expected = "GET / HTTP/1.1\r\n\r\n"
        let request = Request(
            method: .get,
            uri: URL(string: "/")!,
            version: Version(major: 1, minor: 1),
            rawHeaders: [],
            body: []
        )
        let actual = String(bytes: request.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual request, \(actual), did not match expected.")
    }

    func testHeaderSerialization() {
        let expected = "GET / HTTP/1.1\r\nAccept: */*\r\n" +
        "Host: www.google.com\r\nConnection: Keep-Alive\r\n\r\n"
        let request = Request(
            method: .get,
            uri: URL(string: "/")!,
            version: Version(major: 1, minor: 1),
            rawHeaders: ["Accept", "*/*", "Host", "www.google.com", "Connection", "Keep-Alive"],
            body: []
        )
        let actual = String(bytes: request.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual request, \(actual), did not match expected.")
    }

    func testDefaultParameters() {
        let expected = "GET / HTTP/1.1\r\n\r\n"
        let request = Request(
            method: .get,
            uri: URL(string: "/")!
        )
        let actual = String(bytes: request.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual request, \(actual), did not match expected.")
    }

}

extension RequestSerializationTests {
    static var allTests = [
        ("testBasicSerialization", testBasicSerialization),
        ("testHeaderSerialization", testHeaderSerialization),
        ("testDefaultParameters", testDefaultParameters),
    ]
}
