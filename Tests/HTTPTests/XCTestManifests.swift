import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RequestParserTests.allTests),
        testCase(RequestSerializationTests.allTests),
        testCase(ResponseSerializationTests.allTests),
        testCase(HTTPMessageTests.allTests),
    ]
}
#endif
