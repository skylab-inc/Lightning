import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RequestParserTests.allTests),
        testCase(RequestSerializationTests.allTests),
        testCase(ResponseSerializationTests.allTests),
        testCase(RequestParserTests.allTests),
        testCase(HTTPMessageTests.allTests),
        testCase(ServerTests.allTests),
    ]
}
#endif
