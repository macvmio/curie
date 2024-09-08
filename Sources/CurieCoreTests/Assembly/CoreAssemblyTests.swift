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
