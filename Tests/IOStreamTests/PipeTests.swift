@testable import IOStream
import XCTest

class PipeTests: XCTestCase {

    func testPipes() {

//        let receiveExpectation = expectation(description: "Did not receive data from stdin.")
        let stdin = Pipe(fd: .stdin)
        let stdout = Pipe(fd: .stdout)

        // Write to stdout
        let outStream = stdout.write(buffer: Array("Send it in!\n".utf8))
        outStream.onFailed { err in
            XCTFail(String(describing: err))
        }
        outStream.start()

        // Read from stdin
        let inStream = stdin.read()
        inStream.onNext { data in
            // TODO: Some pipe magic to write data to stdin during the test.
            // receiveExpectation.fulfill()
        }
        inStream.onFailed { err in
            XCTFail(String(describing: err))
        }
        inStream.start()

    }

}

extension PipeTests {
    static var allTests = [
        ("testPipes", testPipes),
    ]
}
