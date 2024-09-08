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
