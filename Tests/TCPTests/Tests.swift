@testable import TCP
import XCTest

class TestBasic: XCTestCase {

    func testClientServer() {

        let interruptExpectation = expectation(withDescription: "Did not receive an interrupted read.")
        let receiveMessageExpectation = expectation(withDescription: "Did not receive any message.")
        let completeWriteExpectation = expectation(withDescription: "Did not complete write.")
        let server = try! Server()
        try! server.bind(host: "localhost", port: 50000)

        server.listen().startWithNext { connection in
            let read = connection.read()
            let strings = read.map { String(bytes: $0, encoding: .utf8)! }

            strings.onNext { message in
                receiveMessageExpectation.fulfill()
                XCTAssert(message == "This is a test", "Incorrect message.")
                read.stop()
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
            read.start()
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

        waitForExpectations(withTimeout: 1)
    }

}
