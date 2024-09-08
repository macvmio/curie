//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
        let rows = try subject.executeARPQuery()

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
