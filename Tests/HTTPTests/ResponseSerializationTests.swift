//
//  ResponseSerializationTests.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation
import XCTest
@testable import HTTP

class ResponseSerializationTests: XCTestCase {
    
    func testBasicSerialization() {
        let expected = "HTTP/1.1 200 OK\r\n\r\n"
        let response = Response(
            version: Version(major: 1, minor: 1),
            status: .ok,
            rawHeaders: [],
            body: []
        )
        let actual = String(bytes: response.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual response, \(actual), did not match expected.")
    }
    
    func testHeaderSerialization() {
        let expected =
            "HTTP/1.1 200 OK\r\n" +
            "Date: Sun, 30 Oct 2016 09:06:40 GMT\r\n" +
            "Content-Type: text/html; charset=ISO-8859-1\r\n" +
            "\r\n"
        let response = Response(
            version: Version(major: 1, minor: 1),
            status: .ok,
            rawHeaders: [
                "Date", "Sun, 30 Oct 2016 09:06:40 GMT",
                "Content-Type", "text/html; charset=ISO-8859-1"
            ],
            body: []
        )
        let actual = String(bytes: response.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual request, \(actual), did not match expected.")
    }
    
    func testDefaultParameters() {
        let expected = "HTTP/1.1 200 OK\r\n\r\n"
        let response = Response(status: .ok)
        let actual = String(bytes: response.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual response, \(actual), did not match expected.")
    }
    
    func testJSONSerialization() {
        let expected = "HTTP/1.1 200 OK\r\n" +
        "Content-Type: application/json\r\n" +
        "Content-Length: 31\r\n" +
        "\r\n{\"message\":\"Message received!\"}"
        let response = try! Response(json: ["message": "Message received!"])
        let actual = String(bytes: response.serialized, encoding: .utf8)!
        XCTAssert(expected == actual, "Actual response, \(actual), did not match expected.")
    }
    
}

extension ResponseSerializationTests {
    static var allTests = [
        ("testBasicSerialization", testBasicSerialization),
        ("testHeaderSerialization", testHeaderSerialization),
        ("testDefaultParameters", testDefaultParameters),
        ("testJSONSerialization", testJSONSerialization),
    ]
}
