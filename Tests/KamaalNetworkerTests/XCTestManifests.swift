import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(KamaalNetworkerTests.allTests),
    ]
}
#endif
