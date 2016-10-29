import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TestBasic.allTests),
    ]
}
#endif
