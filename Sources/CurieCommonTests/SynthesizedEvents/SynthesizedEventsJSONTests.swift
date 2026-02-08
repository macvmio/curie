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

@testable import CurieCommon
import Foundation
import XCTest

final class SynthesizedEventsJSONTests: XCTestCase {
    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()

    func testDecodeFromRawJSON_SimpleText() throws {
        let jsonString = """
        "Hello"
        """
        let data = Data(jsonString.utf8)

        let decoded = try decoder.decode(KeyboardInputContent.self, from: data)

        guard case let .text(text) = decoded else {
            XCTFail("Expected .text case")
            return
        }

        XCTAssertEqual(text, "Hello")
    }

    func testDecodeFromRawJSON_KeyWithModifiers() throws {
        let jsonString = """
        {
            "key": "return",
            "modifiers": ["command", "shift"],
            "phase": "press"
        }
        """
        let data = Data(jsonString.utf8)

        let decoded = try decoder.decode(KeyboardInputContent.self, from: data)

        guard case let .key(key, modifiers, phase) = decoded else {
            XCTFail("Expected .key case")
            return
        }

        XCTAssertEqual(key, .return)
        XCTAssertEqual(modifiers, [.command, .shift])
        XCTAssertEqual(phase, .press)
    }

    func testDecodeFromRawJSON_KeyboardInput() throws {
        let jsonString = """
        {
            "content": {
                "key": "tab",
                "modifiers": ["control"],
                "phase": "down"
            },
            "delayAfter": 0.25
        }
        """
        let data = Data(jsonString.utf8)

        let decoded = try decoder.decode(KeyboardInput.self, from: data)

        guard case let .key(key, modifiers, phase) = decoded.content else {
            XCTFail("Expected .key content")
            return
        }

        XCTAssertEqual(key, .tab)
        XCTAssertEqual(modifiers, [.control])
        XCTAssertEqual(phase, .down)
        XCTAssertEqual(decoded.delayAfter, 0.25)
    }

    func testDecodeFromRawJSON_KeyboardInputWithTextContent() throws {
        let jsonString = """
        {
            "content": "Type this text"
        }
        """
        let data = Data(jsonString.utf8)

        let decoded = try decoder.decode(KeyboardInput.self, from: data)

        guard case let .text(text) = decoded.content else {
            XCTFail("Expected .text content")
            return
        }

        XCTAssertEqual(text, "Type this text")
        XCTAssertEqual(decoded.delayAfter, KeyboardInput.defaultdelayAfterStrokes)
    }

    func testKeyboardInput_SpecialCharactersInText() throws {
        let specialText = "Hello\n\tWorld! @#$%^&*()"
        let input = KeyboardInput(content: .text(specialText))
        let data = try encoder.encode(input)

        let decoded = try decoder.decode(KeyboardInput.self, from: data)

        guard case let .text(decodedText) = decoded.content else {
            XCTFail("Expected text content")
            return
        }

        XCTAssertEqual(decodedText, specialText)
    }

    func testKeyboardInput_ZeroDelay() throws {
        let input = KeyboardInput(content: .text("Fast"), delayAfter: 0.0)
        let data = try encoder.encode(input)

        let decoded = try decoder.decode(KeyboardInput.self, from: data)
        XCTAssertEqual(decoded.delayAfter, 0.0)
    }

    func testKeyboardInput_AllModifiersCombined() throws {
        let allModifiers: Set<KeyModifier> = [.shift, .command, .option, .control, .function]
        let input = KeyboardInput(
            content: .key(.space, allModifiers, .press)
        )
        let data = try encoder.encode(input)

        let decoded = try decoder.decode(KeyboardInput.self, from: data)

        guard case let .key(key, modifiers, phase) = decoded.content else {
            XCTFail("Expected key content")
            return
        }

        XCTAssertEqual(key, .space)
        XCTAssertEqual(modifiers, allModifiers)
        XCTAssertEqual(phase, .press)
    }
}
