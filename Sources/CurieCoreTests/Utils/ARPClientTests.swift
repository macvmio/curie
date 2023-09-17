import CurieCommonMocks
@testable import CurieCore
import Foundation
import XCTest

final class DefaultARPClientTests: XCTestCase {
    private var subject: DefaultARPClient!
    private var system: MockSystem!

    override func setUp() {
        super.setUp()
        system = MockSystem()
        subject = DefaultARPClient(system: system)
    }

    override func tearDown() {
        system = nil
        subject = nil
        super.tearDown()
    }

    func testExecuteARPA() throws {
        // Given
        system.mockExecuteOutput = """
        ? (192.168.64.81) at 40:7e:c5:b:3:39 on bridge102 ifscope [bridge]
        ? (224.0.0.251) at 1:0:5e:0:0:fb on en0 ifscope permanent [ethernet]
        ? (224.0.0.251) at 1:0:5e:0:0:fb on en7 ifscope permanent [ethernet]
        ? (224.0.0.251) at 1:0:5e:0:0:fb on bridge102 ifscope permanent [ethernet]
        ? (224.0.0.252) at 1:0:5e:0:0:fc on en7 ifscope permanent [ethernet]
        ? (239.255.255.250) at 1:0:5e:7f:ff:fa on en0 ifscope permanent [ethernet]
        """

        // When
        let rows = try subject.executeARPA()

        // Then
        XCTAssertEqual(
            rows,
            [
                .init(ip: "192.168.64.81", macAddress: "40:7e:c5:0b:03:39"),
                .init(ip: "224.0.0.251", macAddress: "01:00:5e:00:00:fb"),
                .init(ip: "224.0.0.251", macAddress: "01:00:5e:00:00:fb"),
                .init(ip: "224.0.0.251", macAddress: "01:00:5e:00:00:fb"),
                .init(ip: "224.0.0.252", macAddress: "01:00:5e:00:00:fc"),
                .init(ip: "239.255.255.250", macAddress: "01:00:5e:7f:ff:fa"),
            ]
        )
    }
}
