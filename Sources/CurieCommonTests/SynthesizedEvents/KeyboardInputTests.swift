//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
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
import XCTest

final class KeyboardInputTests: XCTestCase {
    private lazy var encoder = JSONEncoder()

    override func setUp() {
        super.setUp()
        encoder.outputFormatting = [.sortedKeys]
    }

    func testKeyboardInput_TextContent_DefaultDelay() throws {
        let input = KeyboardInput(content: .text("Test"))
        let data = try encoder.encode(input)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(json, """
        {"content":"Test"}
        """.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testKeyboardInput_TextContent_CustomDelay() throws {
        let customDelay: TimeInterval = 0.5
        let input = KeyboardInput(content: .text("Test"), delayAfter: customDelay)
        let data = try encoder.encode(input)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(json, """
        {"content":"Test","delayAfter":0.5}
        """.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testKeyboardInput_KeyContent_WithModifier() throws {
        let input = KeyboardInput(
            content: .key(.escape, modifiers: [.command], phase: .down),
            delayAfter: 0.2
        )
        let data = try encoder.encode(input)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(json, """
        {"content":{"key":"escape","modifiers":["command"],"phase":"down"},"delayAfter":0.2}
        """.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
