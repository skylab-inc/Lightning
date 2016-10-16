/*import XCTest
@testable import HTTP

class ResponseParserTests: XCTestCase {
 
    func testInvalidResponse() {
        let parser = ResponseParser()
        do {
            let data = ("FTP/1.1 200 OK\r\n" +
                        "\r\n")
            try parser.parse(data)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    func testShortResponse() {
        let parser = ResponseParser()
        do {
            let data = "HTTP/1.1 200 OK\r\n" +
                         "Content-Length: 0\r\n" +
                        "\r\n"
            if let response = try parser.parse(data) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers.count == 1)
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testDiscontinuousShortResponse() {
        let parser = ResponseParser()
        do {
            let data1 = "HTT"
            let data2 = "P/1."
            let data3 = "1 200 OK\r\n"
            let data4 = "Content-Length: 0\r\n"
            let data5 = "\r\n"

            var response = try parser.parse(data1)
            XCTAssert(response == nil)
            response = try parser.parse(data2)
            XCTAssert(response == nil)
            response = try parser.parse(data3)
            XCTAssert(response == nil)
            response = try parser.parse(data4)
            XCTAssert(response == nil)
            if let response = try parser.parse(data5) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers.count == 1)
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testMediumResponse() {
        let parser = ResponseParser()
        do {
            let data = ("HTTP/1.1 200 OK\r\n" +
                        "Host: zewo.co\r\n" +
                        "Content-Length: 0\r\n" +
                        "\r\n")
            if let response = try parser.parse(data) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Host"] == "zewo.co")

            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testDiscontinuousMediumResponse() {
        let parser = ResponseParser()
        do {
            let data1 = "HTT"
            let data2 = "P/1.1 200 OK\r\n"
            let data3 = "Hos"
            let data4 = "t: zewo.c"
            let data5 = "o\r\n"
            let data6 = "Conten"
            let data7 = "t-Length: "
            let data8 = "0\r\n"
            let data9 = "\r"
            let data10 = "\n"

            var response = try parser.parse(data1)
            XCTAssert(response == nil)
            response = try parser.parse(data2)
            XCTAssert(response == nil)
            response = try parser.parse(data3)
            XCTAssert(response == nil)
            response = try parser.parse(data4)
            XCTAssert(response == nil)
            response = try parser.parse(data5)
            XCTAssert(response == nil)
            response = try parser.parse(data6)
            XCTAssert(response == nil)
            response = try parser.parse(data7)
            XCTAssert(response == nil)
            response = try parser.parse(data8)
            XCTAssert(response == nil)
            response = try parser.parse(data9)
            XCTAssert(response == nil)
            if let response = try parser.parse(data10) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Host"] == "zewo.co")
                XCTAssert(response.headers["Content-Length"] == "0")
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }


    func testDiscontinuousMediumResponseMultipleSetCookie() {
        let parser = ResponseParser()

        do {
            let data1 = "HTT"
            let data2 = "P/1.1 200 OK\r\n"
            let data3 = "Hos"
            let data4 = "t: zewo.c"
            let data5 = "o\r\n"
            let data6 = "Set-"
            let data7 = "Cookie: serv"
            let data8 = "er=zewo\r\n"
            let data9 = "Set-"
            let data10 = "Cookie: lan"
            let data11 = "g=swift\r\n"
            let data12 = "Content-Length: 0\r\n"
            let data13 = "\r"
            let data14 = "\n"

            var response = try parser.parse(data1)
            XCTAssert(response == nil)
            response = try parser.parse(data2)
            XCTAssert(response == nil)
            response = try parser.parse(data3)
            XCTAssert(response == nil)
            response = try parser.parse(data4)
            XCTAssert(response == nil)
            response = try parser.parse(data5)
            XCTAssert(response == nil)
            response = try parser.parse(data6)
            XCTAssert(response == nil)
            response = try parser.parse(data7)
            XCTAssert(response == nil)
            response = try parser.parse(data8)
            XCTAssert(response == nil)
            response = try parser.parse(data9)
            XCTAssert(response == nil)
            response = try parser.parse(data10)
            XCTAssert(response == nil)
            response = try parser.parse(data11)
            XCTAssert(response == nil)
            response = try parser.parse(data12)
            XCTAssert(response == nil)
            response = try parser.parse(data13)
            XCTAssert(response == nil)
            if let response = try parser.parse(data14) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Host"] == "zewo.co")
                XCTAssert(response.cookies.contains(Cookie("server=zewo")!))
                XCTAssert(response.cookies.contains(Cookie("lang=swift")!))
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testCompleteResponse() {
        let parser = ResponseParser()
        do {
            let data = ("HTTP/1.1 200 OK\r\n" +
                    "Content-Length: 4\r\n" +
                    "\r\n" +
                    "Zewo")
            if let response = try parser.parse(data) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Content-Length"] == "4")
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testDiscontinuousCompleteResponse() {
        let parser = ResponseParser()
        do {
            let data1 = "HT"
            let data2 = "TP/1.1 20"
            let data3 = "0 O"
            let data4 = "K\r\n"
            let data5 = "Cont"
            let data6 = "ent-Length: 4"
            let data7 = "\r\n"
            let data8 = "\r"
            let data9 = "\n"
            let data10 = "Ze"
            let data11 = "wo"

            var response = try parser.parse(data1)
            XCTAssert(response == nil)
            response = try parser.parse(data2)
            XCTAssert(response == nil)
            response = try parser.parse(data3)
            XCTAssert(response == nil)
            response = try parser.parse(data4)
            XCTAssert(response == nil)
            response = try parser.parse(data5)
            XCTAssert(response == nil)
            response = try parser.parse(data6)
            XCTAssert(response == nil)
            response = try parser.parse(data7)
            XCTAssert(response == nil)
            response = try parser.parse(data8)
            XCTAssert(response == nil)
            response = try parser.parse(data9)
            XCTAssert(response == nil)
            response = try parser.parse(data10)
            XCTAssert(response == nil)
            if let response = try parser.parse(data11) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Content-Length"] == "4")
            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testMultipleShortResponsesInTheSameStream() {
        let parser = ResponseParser()
        do {
            let data1 = "HT"
            let data2 = "TP/1."
            let data3 = "1 200 OK\r\n"
            let data4 = "Content-Length: 0\r\n"
            let data5 = "\r\n"

            var response = try parser.parse(data1)
            XCTAssert(response == nil)
            response = try parser.parse(data2)
            XCTAssert(response == nil)
            response = try parser.parse(data3)
            XCTAssert(response == nil)
            response = try parser.parse(data4)
            XCTAssert(response == nil)

            if let response = try parser.parse(data5) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers.count == 1)
            } else {
                XCTAssert(false)
            }

            let data6 = "HT"
            let data7 = "TP/1."
            let data8 = "1 200 OK\r\n"
            let data9 = "Content-Length: 0\r\n"
            let data10 = "\r\n"

            response = try parser.parse(data6)
            XCTAssert(response == nil)
            response = try parser.parse(data7)
            XCTAssert(response == nil)
            response = try parser.parse(data8)
            XCTAssert(response == nil)
            response = try parser.parse(data9)
            XCTAssert(response == nil)

            if let response = try parser.parse(data10) {
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers.count == 1)

            } else {
                XCTAssert(false)
            }
        } catch {
            XCTAssert(false)
        }
    }

    func testManyResponses() {
        #if os(OSX)
            let data = ("HTTP/1.1 200 OK\r\n" +
                        "Content-Length: 4\r\n" +
                        "\r\n" +
                        "Zewo")

            self.measure {
                for _ in 0 ..< 10000 {
                    let parser = ResponseParser()
                    do {
                        if let response = try parser.parse(data) {
                            XCTAssert(response.status == .ok)
                        } else {
                            XCTAssert(false)
                        }
                    } catch {
                        XCTAssert(false)
                    }
                }
            }
        #endif
    }
    */
//
//    func testUpgradeResponses() {
//        let parser = HTTPResponseParser { _ in
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
//        let parser = HTTPResponseParser { response in
//            XCTAssert(response.method == .GET)
//            XCTAssert(response.uri.path == "/")
//            XCTAssert(response.majorVersion == 1)
//            XCTAssert(response.minorVersion == 1)
//            XCTAssert(response.headers["Transfer-Encoding"] == "chunked")
//            XCTAssert(response.body == "Zewo".bytes)
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
//        let parser = HTTPResponseParser { _ in
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
//        let parser = HTTPResponseParser { _ in
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
//        let parser = HTTPResponseParser { _ in
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
//        let parser = HTTPResponseParser { response in
//            XCTAssert(response.method == .GET)
//            XCTAssert(response.uri.path == "/")
//            XCTAssert(response.majorVersion == 1)
//            XCTAssert(response.minorVersion == 1)
//            XCTAssert(response.headers["Connection"] == "keep-alive")
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
//        let parser = HTTPResponseParser { response in
//            XCTAssert(response.method == .GET)
//            XCTAssert(response.uri.path == "/")
//            XCTAssert(response.majorVersion == 1)
//            XCTAssert(response.minorVersion == 1)
//            XCTAssert(response.headers["Connection"] == "close")
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
//    func testResponseHTTP1_0() {
//        let parser = HTTPResponseParser { response in
//            XCTAssert(response.method == .GET)
//            XCTAssert(response.uri.path == "/")
//            XCTAssert(response.majorVersion == 1)
//            XCTAssert(response.minorVersion == 0)
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
/*}



extension ResponseParserTests {
    static var allTests: [(String, (ResponseParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidResponse", testInvalidResponse),
            ("testShortResponse", testShortResponse),
            ("testDiscontinuousShortResponse", testDiscontinuousShortResponse),
            ("testMediumResponse", testMediumResponse),
            ("testDiscontinuousMediumResponse", testDiscontinuousMediumResponse),
            ("testDiscontinuousMediumResponseMultipleSetCookie", testDiscontinuousMediumResponseMultipleSetCookie),
            ("testCompleteResponse", testCompleteResponse),
            ("testDiscontinuousCompleteResponse", testDiscontinuousCompleteResponse),
            ("testMultipleShortResponsesInTheSameStream", testMultipleShortResponsesInTheSameStream),
            ("testManyResponses", testManyResponses),
        ]
    }
}*/

