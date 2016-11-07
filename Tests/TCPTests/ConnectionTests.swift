@testable import TCP
import XCTest

class ConnectionTests: XCTestCase {

    func testClientServer() {

        // TODO: YEA! This is terrible! But there appears to be a bug with
        // XCTest. On Linux `swift test` exits with error code 1 and no further
        // output. None of the failure conditions are met however.
        #if !os(Linux)
            let interruptExpectation = expectation(description: "Did not receive an interrupted read.")
            let receiveMessageExpectation = expectation(description: "Did not receive any message.")
            let completeWriteExpectation = expectation(description: "Did not complete write.")
            let server = try! Server()
            try! server.bind(host: "localhost", port: 50000)

            server.listen().startWithNext { connection in
                let strings = connection
                    .read()
                    .map { String(bytes: $0, encoding: .utf8)! }

                strings.onNext { message in
                    receiveMessageExpectation.fulfill()
                    XCTAssert(message == "This is a test", "Incorrect message.")
                    strings.stop()
                }

                strings.onInterrupted {
                    interruptExpectation.fulfill()
                }

                strings.onFailed { error in
                    XCTFail("Read failed with error: \(error)")
                }

                strings.onCompleted {
                    XCTFail("Completed instead of interrupt.")
                }
                
                strings.start()
            }

            let socket = try! Socket()
            let connect = socket.connect(host: "localhost", port: 50000)
            connect.onCompleted {
                let buffer = Array("This is a test".utf8)
                let write = socket.write(buffer: buffer)
                write.onCompleted {
                    completeWriteExpectation.fulfill()
                    connect.stop()
                }
                write.onFailed { error in
                    XCTFail("Write failed with error: \(error)")
                }
                write.start()
            }
            connect.onFailed { error in
                XCTFail("Connection failed with error: \(error)")
            }
            connect.start()

            waitForExpectations(timeout: 1)
        #endif
    }

}

extension ConnectionTests {
    static var allTests = [
        ("testClientServer", testClientServer),
    ]
}
