import XCTest
@testable import HTTP

class RequestParserTests: XCTestCase {

    func testInvalidMethod() {
        let expectParseError = expectation(description: "Invalid request did not throw an error.")
        let parser = RequestParser()
        let data = ("INVALID / HTTP/1.1\r\n" + "\r\n")
        do {
            try parser.parse(Data(data.utf8))
        } catch {
            expectParseError.fulfill()
        }
        waitForExpectations(timeout: 0)
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
                XCTAssert(request.uri.path == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            }
            do {
                try parser.parse(Data(data.utf8))
            } catch {
                XCTFail("Parsing error \(error) for method \(method)")
            }
            XCTAssert(
                numberParsed == 1,
                "Parse produced incorrect number of requests: \(numberParsed)"
            )
        }
    }

    func testDiscontinuousShortRequest() {
        var numberParsed = 0
        let parser = RequestParser { request in
            numberParsed += 1
            XCTAssert(request.method == .get)
            XCTAssert(request.uri.path == "/")
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
                try parser.parse(Data(data.utf8))
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
            XCTAssert(request.uri.path == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.rawHeaders[0] == "Host")
            XCTAssert(request.rawHeaders[1] == "swift.org")
        }
        do {
            try parser.parse(Data(data.utf8))
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
            XCTAssert(request.uri.path == "/")
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
                try parser.parse(Data(data.utf8))
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
            XCTAssert(request.uri.path == "/")
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
                try parser.parse(Data(data.utf8))
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
            XCTAssert(request.uri.path == "/")
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
            try parser.parse(Data(data.utf8))
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
            XCTAssert(request.uri.path == "/profile")
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
                try parser.parse(Data(data.utf8))
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
                XCTAssert(request.uri.path == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            } else if numberParsed == 2 {
                XCTAssert(request.method == .head)
                XCTAssert(request.uri.path == "/profile")
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
                try parser.parse(Data(data.utf8))
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
                XCTAssert(request.uri.path == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            } else if numberParsed == 2 {
                XCTAssert(request.method == .head)
                XCTAssert(request.uri.path == "/profile")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders.count == 0)
            }
        }
        let data = "GET / HTTP/1.1\r\n\r\nHEAD /profile HTTP/1.1\r\n\r\n"
        do {
            try parser.parse(Data(data.utf8))
        } catch {
            XCTFail("Parsing error \(error).")
        }
        XCTAssert(numberParsed == 2, "Parse produced incorrect number of requests: \(numberParsed)")
    }

    func testManyRequests() {
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
                XCTAssert(request.uri.path == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.rawHeaders[0] == "Content-Length")
                XCTAssert(request.rawHeaders[1] == "5")
            }
            for _ in 0 ..< messageNumber {
                do {
                    try parser.parse(Data(data.utf8))
                } catch {
                    XCTFail("Parsing error \(error).")
                }
            }
            XCTAssert(
                numberParsed == messageNumber,
                "Parse produced incorrect number of requests: \(numberParsed)"
            )
        }
    }
}

extension RequestParserTests {
    static var allTests: [(String, (RequestParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidMethod", testInvalidMethod),
            ("testShortRequests", testShortRequests),
            ("testDiscontinuousShortRequest", testDiscontinuousShortRequest),
            ("testMediumRequest", testMediumRequest),
            ("testDiscontinuousMediumRequest", testDiscontinuousMediumRequest),
            ("testDiscontinuousMediumRequestMultipleCookie",
              testDiscontinuousMediumRequestMultipleCookie),
            ("testCompleteRequest", testCompleteRequest),
            ("testDiscontinuousCompleteRequest", testDiscontinuousCompleteRequest),
            ("testMultipleShortRequestsInTheSameStream", testMultipleShortRequestsInTheSameStream),
            ("testMultipleShortRequestsInSingleMessage", testMultipleShortRequestsInSingleMessage),
            ("testManyRequests", testManyRequests),
        ]
    }
}
