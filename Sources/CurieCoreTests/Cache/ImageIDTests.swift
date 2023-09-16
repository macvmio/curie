@testable import CurieCore
import Foundation
import XCTest

final class ImageIDTests: XCTestCase {
    func testMake() {
        // Given
        let numberOfInstance = 10000

        // When
        let ids = Set((0 ..< numberOfInstance).map { _ in ImageID.make() })

        // Then
        XCTAssertEqual(numberOfInstance, ids.count)
        XCTAssertTrue(ids.allSatisfy { $0.description.count == 12 })
    }
}
