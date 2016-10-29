import XCTest

import HTTPTests
import TCPTests

var tests = [XCTestCaseEntry]()
tests += HTTPTests.allTests()
tests += TCPTests.allTests()
XCTMain(tests)
