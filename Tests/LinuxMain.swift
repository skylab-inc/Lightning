import XCTest

import HTTPTests
import TCPTests
import IOStreamTests

var tests = [XCTestCaseEntry]()
tests += HTTPTests.allTests()
tests += TCPTests.allTests()
tests += IOStreamTests.allTests()
XCTMain(tests)
