import XCTest
@testable import HTTP

class RequestParserTests: XCTestCase {

    func testInvalidMethod() {
        let expectParseError = expectation(withDescription: "Invalid request did not throw an error.")
        let parser = RequestParser()
        let data = ("INVALID / HTTP/1.1\r\n" + "\r\n")
        do {
            try parser.parse(Array(data.utf8))
        } catch {
            expectParseError.fulfill()
        }
        waitForExpectations(withTimeout: 0)
    }

    func testShortRequests() {
        let methods = [
            "DELETE",
            "GET",
            "HEAD",
            "POST",
            "PUT",
            "CONNECT",
            "OPTIONS",
            "TRACE",
            "COPY",
            "LOCK",
            "MKCOL",
            "MOVE",
            "PROPFIND",
            "PROPPATCH",
            "SEARCH",
            "UNLOCK",
            "BIND",
            "REBIND",
            "UNBIND",
            "ACL",
            "REPORT",
            "MKACTIVITY",
            "CHECKOUT",
            "MERGE",
            "M-SEARCH",
            "NOTIFY",
            "SUBSCRIBE",
            "UNSUBSCRIBE",
            "PATCH",
            "PURGE",
            "MKCALENDAR",
            "LINK",
            "UNLINK"
        ]
        for (i, method) in methods.enumerated() {
            var numberParsed = 0
            let data = ("\(method) / HTTP/1.1\r\n" + "\r\n")
            let parser = RequestParser { request in
                numberParsed += 1
                XCTAssert(request.method == Method(code: i))
                XCTAssert(request.uri == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            }
            do {
                try parser.parse(Array(data.utf8))
            } catch {
                XCTFail("Parsing error \(error) for method \(method)")
            }
            XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
        }
    }

    func testDiscontinuousShortRequest() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .get)
            XCTAssert(request.uri == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders.count == 0)
        }
        let dataArray = [
            "GET / HT",
            "TP/1.",
            "1\r\n",
            "\r\n"
        ]
        do {
            for data in dataArray {
                try parser.parse(Array(data.utf8))
            }
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testMediumRequest() {
        var numberParsed = 0
        let data = ("GET / HTTP/1.1\r\n" +
                    "Host: swift.org\r\n" +
                    "\r\n")
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .get)
            XCTAssert(request.uri == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Host")
            XCTAssert(request.rawHeaders[1] == "swift.org")
        }
        do {
            try parser.parse(Array(data.utf8))
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testDiscontinuousMediumRequest() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .get)
            XCTAssert(request.uri == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Host")
            XCTAssert(request.rawHeaders[1] == "swift.org")
        }
        let dataArray = [
            "GET / HTT",
            "P/1.1\r\n",
            "Hos",
            "t: swift.or",
            "g\r\n",
            "Conten",
            "t-Type: appl",
            "ication/json\r\n",
            "\r",
            "\n"
        ]
        do {
            for data in dataArray {
                try parser.parse(Array(data.utf8))
            }
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testDiscontinuousMediumRequestMultipleCookie() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .get)
            XCTAssert(request.uri == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Host")
            XCTAssert(request.rawHeaders[1] == "swift.org")
            XCTAssert(request.rawHeaders[2] == "Cookie")
            XCTAssert(request.rawHeaders[3] == "server=swift")
            XCTAssert(request.rawHeaders[4] == "Cookie")
            XCTAssert(request.rawHeaders[5] == "lang=swift")
        }
        let dataArray = [
            "GET / HTT",
            "P/1.1\r\n",
            "Hos",
            "t: swift.or",
            "g\r\n",
            "C",
            "ookie: serv",
            "er=swift\r\n",
            "C",
            "ookie: lan",
            "g=swift\r\n",
            "\r",
            "\n"
        ]
        do {
            for data in dataArray {
                try parser.parse(Array(data.utf8))
            }
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testCompleteRequest() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .post)
            XCTAssert(request.uri == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Content-Length")
            XCTAssert(request.rawHeaders[1] == "5")
        }
        let data = ("POST / HTTP/1.1\r\n" +
                "Content-Length: 5\r\n" +
                "\r\n" +
                "Swift")
        do {
            try parser.parse(Array(data.utf8))
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testDiscontinuousCompleteRequest() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .post)
            XCTAssert(request.uri == "/profile")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Content-Length")
            XCTAssert(request.rawHeaders[1] == "5")
        }
        let dataArray = [
            "PO",
            "ST /pro",
            "file HTT",
            "P/1.1\r\n",
            "Cont",
            "ent-Length: 5",
            "\r\n",
            "\r",
            "\n",
            "Swi",
            "ft"
        ]
        do {
            for data in dataArray {
                try parser.parse(Array(data.utf8))
            }
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 1, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testMultipleShortRequestsInTheSameStream() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            if numberParsed == 1 {
                XCTAssert(request.method == .get)
                XCTAssert(request.uri == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            } else if numberParsed == 2 {
                XCTAssert(request.method == .head)
                XCTAssert(request.uri == "/profile")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            }
        }
        let dataArray = [
            "GET / HT",
            "TP/1.",
            "1\r\n",
            "\r\n",
            "HEAD /profile HT",
            "TP/1.",
            "1\r\n",
            "\r\n"
        ]
        do {
            for data in dataArray {
                try parser.parse(Array(data.utf8))
            }
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 2, "Parse produced incorrect number of requests: \(numberParsed)")
    }
    
    func testMultipleShortRequestsInSingleMessage() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            if numberParsed == 1 {
                XCTAssert(request.method == .get)
                XCTAssert(request.uri == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            } else if numberParsed == 2 {
                XCTAssert(request.method == .head)
                XCTAssert(request.uri == "/profile")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            }
        }
        let data = "GET / HTTP/1.1\r\n\r\nHEAD /profile HTTP/1.1\r\n\r\n"
        do {
            try parser.parse(Array(data.utf8))
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 2, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testManyRequests() {
        #if os(OSX)
            let data = ("POST / HTTP/1.1\r\n" +
                        "Content-Length: 5\r\n" +
                        "\r\n" +
                        "Swift")
            self.measure {
                var numberParsed = 0
                let messageNumber = 10000
                let parser = RequestParser { request in
                    numberParsed += 1
                    XCTAssert(request.method == .post)
                    XCTAssert(request.uri == "/")
                    XCTAssert(request.version.major == 1)
                    XCTAssert(request.version.minor == 1)
                    XCTAssert(request.rawHeaders[0] == "Content-Length")
                    XCTAssert(request.rawHeaders[1] == "5")
                }
                for _ in 0 ..< messageNumber {
                    do {
                        try parser.parse(Array(data.utf8))
                    } catch {
                        XCTFail("Parsing error \(error).")
                    }
                }
                XCTAssert(numberParsed == messageNumber, "Parse produced incorrect number of requests: \(numberParsed)")
            }
        #endif
    }
//
//    func testUpgradeRequests() {
//        let parser = HTTPRequestParser { _ in
//            XCTAssert(true)
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Upgrade: WebSocket\r\n" +
//                "Connection: Upgrade\r\n" +
//                "\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//
//    func testChunkedEncoding() {
//        let parser = HTTPRequestParser { request in
//            XCTAssert(request.method == .GET)
//            XCTAssert(request.uri.path == "/")
//            XCTAssert(request.majorVersion == 1)
//            XCTAssert(request.minorVersion == 1)
//            XCTAssert(request.headers["Transfer-Encoding"] == "chunked")
//            XCTAssert(request.body == "Zewo".bytes)
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Transfer-Encoding: chunked\r\n" +
//                "\r\n" +
//                "4\r\n" +
//                "Zewo\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(false)
//        }
//    }
//
//    func testIncorrectContentLength() {
//        let parser = HTTPRequestParser { _ in
//            XCTAssert(false)
//        }
//
//        do {
//            let data = ("POST / HTTP/1.1\r\n" +
//                "Content-Length: 5\r\n" +
//                "\r\n" +
//                "Zewo")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//
//    func testIncorrectChunkSize() {
//        let parser = HTTPRequestParser { _ in
//            XCTAssert(false)
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Transfer-Encoding: chunked\r\n" +
//                "\r\n" +
//                "5\r\n" +
//                "Zewo\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//
//    func testInvalidChunkSize() {
//        let parser = HTTPRequestParser { _ in
//            XCTAssert(false)
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Transfer-Encoding: chunked\r\n" +
//                "\r\n" +
//                "x\r\n" +
//                "Zewo\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//
//    func testConnectionKeepAlive() {
//        let parser = HTTPRequestParser { request in
//            XCTAssert(request.method == .GET)
//            XCTAssert(request.uri.path == "/")
//            XCTAssert(request.majorVersion == 1)
//            XCTAssert(request.minorVersion == 1)
//            XCTAssert(request.headers["Connection"] == "keep-alive")
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Connection: keep-alive\r\n" +
//                "\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(false)
//        }
//    }
//
//    func testConnectionClose() {
//        let parser = HTTPRequestParser { request in
//            XCTAssert(request.method == .GET)
//            XCTAssert(request.uri.path == "/")
//            XCTAssert(request.majorVersion == 1)
//            XCTAssert(request.minorVersion == 1)
//            XCTAssert(request.headers["Connection"] == "close")
//        }
//
//        do {
//            let data = ("GET / HTTP/1.1\r\n" +
//                "Connection: close\r\n" +
//                "\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(false)
//        }
//    }
//
//    func testRequestHTTP1_0() {
//        let parser = HTTPRequestParser { request in
//            XCTAssert(request.method == .GET)
//            XCTAssert(request.uri.path == "/")
//            XCTAssert(request.majorVersion == 1)
//            XCTAssert(request.minorVersion == 0)
//        }
//
//        do {
//            let data = ("GET / HTTP/1.0\r\n" +
//                "\r\n")
//            try parser.parse(data)
//        } catch {
//            XCTAssert(false)
//        }
//    }
//
//    func testURI() {
//        let URIString = "http://username:password@www.google.com:777/foo/bar?foo=bar&for=baz#yeah"
//        let uri = URI(string: URIString)
//        XCTAssert(uri.scheme == "http")
//        XCTAssert(uri.userInfo?.username == "username")
//        XCTAssert(uri.userInfo?.password == "password")
//        XCTAssert(uri.host == "www.google.com")
//        XCTAssert(uri.port == 777)
//        XCTAssert(uri.path == "/foo/bar")
//        XCTAssert(uri.query["foo"] == "bar")
//        XCTAssert(uri.query["for"] == "baz")
//        XCTAssert(uri.fragment == "yeah")
//    }
//
//    func testURIIPv6() {
//        let URIString = "http://username:password@[2001:db8:1f70::999:de8:7648:6e8]:100/foo/bar?foo=bar&for=baz#yeah"
//        let uri = URI(string: URIString)
//        XCTAssert(uri.scheme == "http")
//        XCTAssert(uri.userInfo?.username == "username")
//        XCTAssert(uri.userInfo?.password == "password")
//        XCTAssert(uri.host == "2001:db8:1f70::999:de8:7648:6e8")
//        XCTAssert(uri.port == 100)
//        XCTAssert(uri.path == "/foo/bar")
//        XCTAssert(uri.query["foo"] == "bar")
//        XCTAssert(uri.query["for"] == "baz")
//        XCTAssert(uri.fragment == "yeah")
//    }
//
//    func testURIIPv6WithZone() {
//        let URIString = "http://username:password@[2001:db8:a0b:12f0::1%eth0]:100/foo/bar?foo=bar&for=baz#yeah"
//        let uri = URI(string: URIString)
//        XCTAssert(uri.scheme == "http")
//        XCTAssert(uri.userInfo?.username == "username")
//        XCTAssert(uri.userInfo?.password == "password")
//        XCTAssert(uri.host == "2001:db8:a0b:12f0::1%eth0")
//        XCTAssert(uri.port == 100)
//        XCTAssert(uri.path == "/foo/bar")
//        XCTAssert(uri.query["foo"] == "bar")
//        XCTAssert(uri.query["for"] == "baz")
//        XCTAssert(uri.fragment == "yeah")
//    }
//
//    func testQueryElementWitoutValue() {
//        let URIString = "http://username:password@[2001:db8:a0b:12f0::1%eth0]:100/foo/bar?foo=&for#yeah"
//        let uri = URI(string: URIString)
//        XCTAssert(uri.scheme == "http")
//        XCTAssert(uri.userInfo?.username == "username")
//        XCTAssert(uri.userInfo?.password == "password")
//        XCTAssert(uri.host == "2001:db8:a0b:12f0::1%eth0")
//        XCTAssert(uri.port == 100)
//        XCTAssert(uri.path == "/foo/bar")
//        XCTAssert(uri.query["foo"] == "")
//        XCTAssert(uri.query["for"] == "")
//        XCTAssert(uri.fragment == "yeah")
//    }
}



extension RequestParserTests {
    static var allTests: [(String, (RequestParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidMethod", testInvalidMethod),
            ("testShortRequests", testShortRequests),
            ("testDiscontinuousShortRequest", testDiscontinuousShortRequest),
            ("testMediumRequest", testMediumRequest),
            ("testDiscontinuousMediumRequest", testDiscontinuousMediumRequest),
            ("testDiscontinuousMediumRequestMultipleCookie", testDiscontinuousMediumRequestMultipleCookie),
            ("testCompleteRequest", testCompleteRequest),
            ("testDiscontinuousCompleteRequest", testDiscontinuousCompleteRequest),
            ("testMultipleShortRequestsInTheSameStream", testMultipleShortRequestsInTheSameStream),
            ("testManyRequests", testManyRequests),
        ]
    }
}
