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

import Carbon.HIToolbox

final class CharacterKeyMapping {
    static let shared = CharacterKeyMapping()

    private let characterMappings: [Character: (code: Int, needsShift: Bool)]

    private init() {
        var mappings: [Character: (code: Int, needsShift: Bool)] = [:]

        Self.addLetterMappings(to: &mappings)
        Self.addNumberMappings(to: &mappings)
        Self.addShiftedSymbolMappings(to: &mappings)
        Self.addUnshiftedSymbolMappings(to: &mappings)

        characterMappings = mappings
    }

    private static func addLetterMappings(to mappings: inout [Character: (code: Int, needsShift: Bool)]) {
        let letterKeyCodes = [
            kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F,
            kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L,
            kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_Q, kVK_ANSI_R,
            kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
            kVK_ANSI_Y, kVK_ANSI_Z,
        ]

        for (index, keyCode) in letterKeyCodes.enumerated() {
            let lowercaseChar = Character(UnicodeScalar(97 + index)!) // 'a' + index
            let uppercaseChar = Character(UnicodeScalar(65 + index)!) // 'A' + index
            mappings[lowercaseChar] = (keyCode, false)
            mappings[uppercaseChar] = (keyCode, true)
        }
    }

    private static func addNumberMappings(to mappings: inout [Character: (code: Int, needsShift: Bool)]) {
        let numberKeyCodes = [
            kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4,
            kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
        ]

        for (index, keyCode) in numberKeyCodes.enumerated() {
            mappings[Character(String(index))] = (keyCode, false)
        }
    }

    private static func addShiftedSymbolMappings(to mappings: inout [Character: (code: Int, needsShift: Bool)]) {
        let shiftedSymbols: [(Character, Int)] = [
            ("!", kVK_ANSI_1), ("@", kVK_ANSI_2), ("#", kVK_ANSI_3), ("$", kVK_ANSI_4),
            ("%", kVK_ANSI_5), ("^", kVK_ANSI_6), ("&", kVK_ANSI_7), ("*", kVK_ANSI_8),
            ("(", kVK_ANSI_9), (")", kVK_ANSI_0), ("_", kVK_ANSI_Minus), ("+", kVK_ANSI_Equal),
            ("{", kVK_ANSI_LeftBracket), ("}", kVK_ANSI_RightBracket), ("|", kVK_ANSI_Backslash),
            (":", kVK_ANSI_Semicolon), ("\"", kVK_ANSI_Quote), ("<", kVK_ANSI_Comma),
            (">", kVK_ANSI_Period), ("?", kVK_ANSI_Slash), ("~", kVK_ANSI_Grave),
        ]

        for (char, keyCode) in shiftedSymbols {
            mappings[char] = (keyCode, true)
        }
    }

    private static func addUnshiftedSymbolMappings(to mappings: inout [Character: (code: Int, needsShift: Bool)]) {
        let unshiftedSymbols: [(Character, Int)] = [
            ("-", kVK_ANSI_Minus), ("=", kVK_ANSI_Equal), ("[", kVK_ANSI_LeftBracket),
            ("]", kVK_ANSI_RightBracket), ("\\", kVK_ANSI_Backslash), (";", kVK_ANSI_Semicolon),
            ("'", kVK_ANSI_Quote), (",", kVK_ANSI_Comma), (".", kVK_ANSI_Period),
            ("/", kVK_ANSI_Slash), ("`", kVK_ANSI_Grave), (" ", kVK_Space),
        ]

        for (char, keyCode) in unshiftedSymbols {
            mappings[char] = (keyCode, false)
        }
    }

    func mapping(for character: Character) -> ModifiedVirtualKey? {
        guard let mapping = characterMappings[character] else { return nil }

        let originalChar = String(character)
        let unmodifiedChar = mapping.needsShift ? originalChar.lowercased() : originalChar

        return ModifiedVirtualKey(
            virtualKey: VirtualKey(
                code: mapping.code,
                characters: originalChar,
                charactersIgnoringModifiers: unmodifiedChar
            ),
            modifierFlags: mapping.needsShift ? .shift : []
        )
    }

    static func fallback(for character: Character) -> ModifiedVirtualKey {
        let original = String(character)
        let code = character.asciiValue.map(Int.init) ?? kVK_ANSI_Period

        return ModifiedVirtualKey(
            virtualKey: VirtualKey(
                code: code,
                characters: original,
                charactersIgnoringModifiers: original.lowercased()
            ),
            modifierFlags: character.isUppercase ? .shift : []
        )
    }
}
