//
//  HTTPMessageTests.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation
import XCTest
@testable import HTTP

class HTTPMessageTests: XCTestCase {

    struct TestMessageType: HTTPMessage {
        var version = Version(major: 1, minor: 1)
        var rawHeaders: [String] = []
        var cookies: [String] {
            return lowercasedRawHeaderPairs.filter { (key, value) in
                key == "set-cookie"
            }.map { $0.1 }
        }
        var body: [UInt8] = []
    }

    func testHeaders() {
        var testMessage = TestMessageType()
        testMessage.rawHeaders = [
            "Date", "Sun, 30 Oct 2016 09:06:40 GMT",
            "Expires", "-1",
            "Cache-Control", "private, max-age=0",
            "Content-Type", "application/json",
            "Content-Type", "text/html; charset=ISO-8859-1",
            "P3P", "CP=\"See https://www.google.com/support/accounts/answer/151657?hl=en.\"",
            "Server", "gws",
            "Server", "gws", // Duplicate servers for test purposes.
            "X-XSS-Protection", "1; mode=block",
            "X-Frame-Options", "SAMEORIGIN",
            "Set-Cookie", "NID=89=c6V5PAWCEOXgvA6TQrNSR8Pnih2iX3Aa3rIQS005IG6WS8RHH" +
                "_3YTmymtEk5yMxLkz19C_qr2zBNspy7zwubAVo38-kIdjbArSJcXCBbjCcn_hJ" +
                "TEi9grq_ZgHxZTZ5V2YLnH3uxx6U4EA; expires=Mon, 01-May-2017 09:06:40 GMT;" +
                " path=/; domain=.google.com; HttpOnly",
            "Accept-Ranges", "none",
            "Vary", "Accept-Encoding",
            "Transfer-Encoding", "chunked"
        ]
        let expectedHeaders = [
            "date": "Sun, 30 Oct 2016 09:06:40 GMT",
            "expires": "-1",
            "cache-control": "private, max-age=0",
            "content-type": "text/html; charset=ISO-8859-1",
            "p3p": "CP=\"See https://www.google.com/support/accounts/answer/151657?hl=en.\"",
            "server": "gws, gws",
            "x-xss-protection": "1; mode=block",
            "x-frame-options": "SAMEORIGIN",
            "accept-ranges": "none",
            "vary": "Accept-Encoding",
            "transfer-encoding": "chunked"
        ]
        XCTAssert(
            testMessage.headers == expectedHeaders,
            "Actual headers, \(testMessage.headers), did not match expected."
        )
        let expectedCookies = [
            "NID=89=c6V5PAWCEOXgvA6TQrNSR8Pnih2iX3Aa3rIQS005IG6WS8RHH" +
            "_3YTmymtEk5yMxLkz19C_qr2zBNspy7zwubAVo38-kIdjbArSJcXCBbjCcn_hJ" +
            "TEi9grq_ZgHxZTZ5V2YLnH3uxx6U4EA; expires=Mon, 01-May-2017 09:06:40 GMT;" +
            " path=/; domain=.google.com; HttpOnly"
        ]
        XCTAssert(
            testMessage.cookies == expectedCookies,
            "Actual cookies, \(testMessage.cookies), did not match expected."
        )

    }

}

extension HTTPMessageTests {
    static var allTests = [
        ("testHeaders", testHeaders),
    ]
}
