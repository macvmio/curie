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

import AppKit
import Carbon.HIToolbox
import CurieCommon
import Foundation

/// Representation of a single key stroke, with relevant modifiers.
struct KeyStroke {
    var modifiedVirtualKey: ModifiedVirtualKey
    var phase: KeyPhase
    var delayAfter: TimeInterval
}

struct KeyStrokeMappingError: Error, CustomStringConvertible {
    public var character: Character
    var description: String {
        "Could not resolve keystroke for character: \(character)"
    }
}

extension KeyStroke {
    // Resolve a character to a physical key code and required modifiers for a U.S. ANSI layout.
    static func modifiedVirtualKey(for character: Character) throws -> ModifiedVirtualKey {
        if character.isNewline {
            return ModifiedVirtualKey(
                virtualKey: VirtualKey(code: kVK_Return, characters: "", charactersIgnoringModifiers: ""),
                modifierFlags: []
            )
        }

        guard let modifiedVirtualKey = CharacterKeyMapping.shared.mapping(for: character) else {
            throw KeyStrokeMappingError(character: character)
        }
        return modifiedVirtualKey
    }

    static func keystrokesForTypingString(
        _ string: String,
        delayAfter: TimeInterval
    ) throws -> [KeyStroke] {
        var strokes: [KeyStroke] = []

        for character in string {
            let baseStroke = try KeyStroke(
                modifiedVirtualKey: modifiedVirtualKey(for: character),
                phase: .press,
                delayAfter: delayAfter
            )

            let (wrappers, unwrappers) = wrappingStrokes(
                for: baseStroke.modifiedVirtualKey.modifierFlags,
                delayAfter: delayAfter
            )

            strokes.append(contentsOf: wrappers)
            strokes.append(baseStroke)
            strokes.append(contentsOf: unwrappers)
        }

        return strokes
    }

    /// Provides additional key strokes for the given modifiers. Part of these are coming before, and others - after the
    /// actual input.
    /// Example: when input is `SHIFT+A`, the `SHIFT` key must be first pressed down, then the `A` key have to be
    /// pressed, then `SHIFT` must be unpressed.
    private static func wrappingStrokes(
        for flags: NSEvent.ModifierFlags,
        delayAfter: TimeInterval
    ) -> (wrappers: [KeyStroke], unwrappers: [KeyStroke]) {
        let allModifyingEvents = KeyModifier.allCases
        var wrappers: [KeyStroke] = []
        var unwrappers: [KeyStroke] = []
        for event in allModifyingEvents where flags.contains(event.nsEventModifierFlags) {
            wrappers.append(
                KeyStroke(
                    modifiedVirtualKey: .unmodified(virtualKey: .modifierKey(code: event.keyCode)),
                    phase: .down,
                    delayAfter: delayAfter
                )
            )
        }
        for event in allModifyingEvents.reversed() where flags.contains(event.nsEventModifierFlags) {
            unwrappers.append(
                KeyStroke(
                    modifiedVirtualKey: .unmodified(virtualKey: .modifierKey(code: event.keyCode)),
                    phase: .up,
                    delayAfter: delayAfter
                )
            )
        }
        return (wrappers, unwrappers)
    }
}
