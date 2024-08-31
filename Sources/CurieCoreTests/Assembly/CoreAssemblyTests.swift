import CurieCommon
@testable import CurieCore
import Foundation
import SCInject
import XCTest

final class CoreAssemblyTests: XCTestCase {
    private var subject: CoreAssembly!
    private var container: DefaultContainer!

    override func setUp() {
        super.setUp()
        subject = CoreAssembly()
        container = DefaultContainer()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        container = nil
    }

    func testValidate() throws {
        // Given
        let assembler = Assembler(container: container)
        _ = assembler.assemble([subject, CommonAssembly()])

        // When / Then
        try container.validate()
    }
}
