import XCTest
@testable import KeyedCache

class KeyedCacheTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(KeyedCache().text, "Hello, World!")
    }


    static var allTests : [(String, (KeyedCacheTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
