import XCTest
@testable import Crumby

final class CrumbyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Crumby().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
