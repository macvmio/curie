//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// You may not use this file except in compliance with the License.
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
import Dispatch
import Foundation

// MARK: - NSApplication driver

extension NSWindow {
    /// Simulate the given sequence of keystrokes, routed through AppKit to the given window (defaults to keyWindow).
    /// - Parameters:
    ///   - keyboardInput: What to input
    public func synthesize(
        keyboardInput: KeyboardInput,
        completion: @escaping () -> Void
    ) {
        let eventGroup = DispatchGroup()
        defer {
            eventGroup.notify(queue: .main) {
                completion()
            }
        }

        var accumulatedDelayAfter: TimeInterval = 0

        let strokes = keyboardInput.allKeyStrokes

        for stroke in strokes {
            let nsEventTypes: [NSEvent.EventType] = stroke.phase.eventTypesToSynthesize

            post(
                nsEventTypes: nsEventTypes,
                code: stroke.modifiedVirtualKey.virtualKey.code,
                characters: stroke.modifiedVirtualKey.virtualKey.characters,
                charactersIgnoringModifiers: stroke.modifiedVirtualKey.virtualKey.charactersIgnoringModifiers,
                modifierFlags: stroke.modifiedVirtualKey.modifierFlags,
                delayAfter: stroke.delayAfter,
                accumulatedDelayAfter: &accumulatedDelayAfter,
                eventGroup: eventGroup
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func post(
        nsEventTypes: [NSEvent.EventType],
        code: Int,
        characters: String,
        charactersIgnoringModifiers: String,
        modifierFlags: NSEvent.ModifierFlags,
        delayAfter: TimeInterval,
        accumulatedDelayAfter: inout TimeInterval,
        eventGroup: DispatchGroup
    ) {
        var timestamp = ProcessInfo.processInfo.systemUptime

        let events = nsEventTypes.compactMap { type in
            NSEvent.keyEvent(
                with: type,
                location: .zero,
                modifierFlags: modifierFlags,
                timestamp: timestamp,
                windowNumber: windowNumber,
                context: nil,
                characters: characters,
                charactersIgnoringModifiers: charactersIgnoringModifiers,
                isARepeat: false,
                keyCode: UInt16(code)
            )
        }

        if events.count != nsEventTypes.count {
            return
        }

        for event in events {
            eventGroup.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelayAfter) { [weak self] in
                self?.sendEvent(event)
                eventGroup.leave()
            }

            timestamp = ProcessInfo.processInfo.systemUptime + delayAfter
            accumulatedDelayAfter += delayAfter
        }
    }
}

// MARK: - Models

extension KeyPhase {
    var eventTypesToSynthesize: [NSEvent.EventType] {
        switch self {
        case .down:
            [.keyDown]
        case .up:
            [.keyUp]
        case .press:
            [.keyDown, .keyUp]
        }
    }
}

extension KeyboardInput {
    var allKeyStrokes: [KeyStroke] {
        switch content {
        case let .text(string):
            return KeyStroke.keystrokesForTypingString(
                string,
                delayAfter: delayAfter
            )
        case let .key(keyboardKey, keyModifiers, keyPhase):
            let keyStroke = KeyStroke(
                modifiedVirtualKey: ModifiedVirtualKey(
                    virtualKey: keyboardKey.virtualKey,
                    modifierFlags: KeyModifier.combinedModifierFlags(from: keyModifiers)
                ),
                phase: keyPhase,
                delayAfter: delayAfter
            )
            return [keyStroke]
        }
    }
}

// MARK: - Models

/// Representation of a single key stroke, with relevant modifiers.
struct KeyStroke {
    var modifiedVirtualKey: ModifiedVirtualKey
    var phase: KeyPhase
    var delayAfter: TimeInterval
}

/// Virtual key with all relevant modifiers
struct ModifiedVirtualKey {
    var virtualKey: VirtualKey
    var modifierFlags: NSEvent.ModifierFlags

    static func withShift(virtualKey: VirtualKey) -> ModifiedVirtualKey {
        ModifiedVirtualKey(virtualKey: virtualKey, modifierFlags: .shift)
    }

    static func unmodified(virtualKey: VirtualKey) -> ModifiedVirtualKey {
        ModifiedVirtualKey(virtualKey: virtualKey, modifierFlags: [])
    }
}

/// Key codes and key contents.
struct VirtualKey {
    var code: Int
    var characters: String
    var charactersIgnoringModifiers: String

    static func modifierKey(code: Int) -> VirtualKey {
        VirtualKey(
            code: code,
            characters: "",
            charactersIgnoringModifiers: ""
        )
    }

    static func specialKey(code: Int, specialKey: NSEvent.SpecialKey) -> VirtualKey {
        VirtualKey(
            code: code,
            characters: String(specialKey.unicodeScalar),
            charactersIgnoringModifiers: String(specialKey.unicodeScalar)
        )
    }
}

// MARK: - Conveniences

extension KeyStroke {
    // Resolve a character to a physical key code and required modifiers for a U.S. ANSI layout.
    // For example: '!' -> (kVK_ANSI_1 + shift), '@' -> (kVK_ANSI_2 + shift), 'A' -> (kVK_ANSI_A + .shift)
    static func modifiedVirtualKey(for character: Character) -> ModifiedVirtualKey {
        // Normalize to string for convenience
        let original = String(character)
        let lower = original.lowercased()

        if let first = lower.first {
            if first >= "a", first <= "z" {
                if let code = first.codeForLowercasedChar {
                    return ModifiedVirtualKey(
                        virtualKey: .init(code: code, characters: original, charactersIgnoringModifiers: lower),
                        modifierFlags: character.isUppercase ? .shift : []
                    )
                }
            }
            if first >= "0", first <= "9" {
                if let code = first.codeForLowercasedChar {
                    return ModifiedVirtualKey(
                        virtualKey: .init(code: code, characters: lower, charactersIgnoringModifiers: lower),
                        modifierFlags: []
                    )
                }
            }
        }

        switch character {
        case "!": return .withShift(virtualKey: .init(
                code: kVK_ANSI_1,
                characters: "!",
                charactersIgnoringModifiers: "1"
            ))
        case "@": return .withShift(virtualKey: .init(
                code: kVK_ANSI_2,
                characters: "@",
                charactersIgnoringModifiers: "2"
            ))
        case "#": return .withShift(virtualKey: .init(
                code: kVK_ANSI_3,
                characters: "#",
                charactersIgnoringModifiers: "3"
            ))
        case "$": return .withShift(virtualKey: .init(
                code: kVK_ANSI_4,
                characters: "$",
                charactersIgnoringModifiers: "4"
            ))
        case "%": return .withShift(virtualKey: .init(
                code: kVK_ANSI_5,
                characters: "%",
                charactersIgnoringModifiers: "5"
            ))
        case "^": return .withShift(virtualKey: .init(
                code: kVK_ANSI_6,
                characters: "^",
                charactersIgnoringModifiers: "6"
            ))
        case "&": return .withShift(virtualKey: .init(
                code: kVK_ANSI_7,
                characters: "&",
                charactersIgnoringModifiers: "7"
            ))
        case "*": return .withShift(virtualKey: .init(
                code: kVK_ANSI_8,
                characters: "*",
                charactersIgnoringModifiers: "8"
            ))
        case "(": return .withShift(virtualKey: .init(
                code: kVK_ANSI_9,
                characters: "(",
                charactersIgnoringModifiers: "9"
            ))
        case ")": return .withShift(virtualKey: .init(
                code: kVK_ANSI_0,
                characters: ")",
                charactersIgnoringModifiers: "0"
            ))
        case "_": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Minus,
                characters: "_",
                charactersIgnoringModifiers: "-"
            ))
        case "+": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Equal,
                characters: "+",
                charactersIgnoringModifiers: "="
            ))
        case "{": return .withShift(virtualKey: .init(
                code: kVK_ANSI_LeftBracket,
                characters: "{",
                charactersIgnoringModifiers: "["
            ))
        case "}": return .withShift(virtualKey: .init(
                code: kVK_ANSI_RightBracket,
                characters: "}",
                charactersIgnoringModifiers: "]"
            ))
        case "|": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Backslash,
                characters: "|",
                charactersIgnoringModifiers: "\\"
            ))
        case ":": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Semicolon,
                characters: ":",
                charactersIgnoringModifiers: ";"
            ))
        case "\"": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Quote,
                characters: "\"",
                charactersIgnoringModifiers: "'"
            ))
        case "<": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Comma,
                characters: "<",
                charactersIgnoringModifiers: ","
            ))
        case ">": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Period,
                characters: ">",
                charactersIgnoringModifiers: "."
            ))
        case "?": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Slash,
                characters: "?",
                charactersIgnoringModifiers: "/"
            ))
        case "~": return .withShift(virtualKey: .init(
                code: kVK_ANSI_Grave,
                characters: "~",
                charactersIgnoringModifiers: "`"
            ))
        case "-": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Minus,
                characters: "-",
                charactersIgnoringModifiers: "-"
            ))
        case "=": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Equal,
                characters: "=",
                charactersIgnoringModifiers: "="
            ))
        case "[": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_LeftBracket,
                characters: "[",
                charactersIgnoringModifiers: "["
            ))
        case "]": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_RightBracket,
                characters: "]",
                charactersIgnoringModifiers: "]"
            ))
        case "\\": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Backslash,
                characters: "\\",
                charactersIgnoringModifiers: "\\"
            ))
        case ";": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Semicolon,
                characters: ";",
                charactersIgnoringModifiers: ";"
            ))
        case "'": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Quote,
                characters: "'",
                charactersIgnoringModifiers: "'"
            ))
        case ",": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Comma,
                characters: ",",
                charactersIgnoringModifiers: ","
            ))
        case ".": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Period,
                characters: ".",
                charactersIgnoringModifiers: "."
            ))
        case "/": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Slash,
                characters: "/",
                charactersIgnoringModifiers: "/"
            ))
        case "`": return .unmodified(virtualKey: .init(
                code: kVK_ANSI_Grave,
                characters: "`",
                charactersIgnoringModifiers: "`"
            ))
        case " ": return .unmodified(virtualKey: .init(
                code: kVK_Space,
                characters: " ",
                charactersIgnoringModifiers: " "
            ))
        default: break
        }

        if character.isNewline {
            return .unmodified(virtualKey: .init(code: kVK_Return, characters: "", charactersIgnoringModifiers: ""))
        }

        var code: Int
        if let asciiValue = character.asciiValue {
            code = Int(asciiValue)
        } else {
            code = kVK_ANSI_Period
            print("Character '\(character)' has no corresponding ASCII value. Using \(code) as a fallback.")
        }

        return ModifiedVirtualKey(
            virtualKey: VirtualKey(
                code: code,
                characters: original,
                charactersIgnoringModifiers: lower
            ),
            modifierFlags: character.isUppercase ? .shift : []
        )
    }

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

    static func keystrokesForTypingString(
        _ string: String,
        delayAfter: TimeInterval
    ) -> [KeyStroke] {
        var strokes: [KeyStroke] = []

        for character in string {
            let baseStroke = KeyStroke(
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
}

extension Character {
    var codeForLowercasedChar: Int? {
        switch self {
        case "0": kVK_ANSI_0
        case "1": kVK_ANSI_1
        case "2": kVK_ANSI_2
        case "3": kVK_ANSI_3
        case "4": kVK_ANSI_4
        case "5": kVK_ANSI_5
        case "6": kVK_ANSI_6
        case "7": kVK_ANSI_7
        case "8": kVK_ANSI_8
        case "9": kVK_ANSI_9
        case "a": kVK_ANSI_A
        case "b": kVK_ANSI_B
        case "c": kVK_ANSI_C
        case "d": kVK_ANSI_D
        case "e": kVK_ANSI_E
        case "f": kVK_ANSI_F
        case "g": kVK_ANSI_G
        case "h": kVK_ANSI_H
        case "i": kVK_ANSI_I
        case "j": kVK_ANSI_J
        case "k": kVK_ANSI_K
        case "l": kVK_ANSI_L
        case "m": kVK_ANSI_M
        case "n": kVK_ANSI_N
        case "o": kVK_ANSI_O
        case "p": kVK_ANSI_P
        case "q": kVK_ANSI_Q
        case "r": kVK_ANSI_R
        case "s": kVK_ANSI_S
        case "t": kVK_ANSI_T
        case "u": kVK_ANSI_U
        case "v": kVK_ANSI_V
        case "w": kVK_ANSI_W
        case "x": kVK_ANSI_X
        case "y": kVK_ANSI_Y
        case "z": kVK_ANSI_Z
        case "`": kVK_ANSI_Grave
        case "-": kVK_ANSI_Minus
        case "=": kVK_ANSI_Equal
        case "[": kVK_ANSI_LeftBracket
        case "]": kVK_ANSI_RightBracket
        case "\\": kVK_ANSI_Backslash
        case ";": kVK_ANSI_Semicolon
        case "'": kVK_ANSI_Quote
        case ",": kVK_ANSI_Comma
        case ".": kVK_ANSI_Period
        case "/": kVK_ANSI_Slash
        case " ": kVK_Space
        default: nil
        }
    }
}

extension KeyboardKey {
    var virtualKey: VirtualKey {
        switch self {
        case .return, .enter:
            .specialKey(code: kVK_Return, specialKey: .carriageReturn)
        case .escape, .esc:
            VirtualKey(code: kVK_Escape, characters: "\u{1B}", charactersIgnoringModifiers: "\u{1B}")
        case .tab:
            VirtualKey.specialKey(code: kVK_Tab, specialKey: .tab)
        case .delete, .deletebackward, .backspace:
            .specialKey(code: kVK_Delete, specialKey: .delete)
        case .deleteforward, .forwarddelete:
            .specialKey(code: kVK_ForwardDelete, specialKey: .deleteForward)
        case .space, .spacebar:
            VirtualKey(code: kVK_Space, characters: " ", charactersIgnoringModifiers: " ")
        case .left, .leftarrow:
            .specialKey(code: kVK_LeftArrow, specialKey: .leftArrow)
        case .right, .rightarrow:
            .specialKey(code: kVK_RightArrow, specialKey: .rightArrow)
        case .up, .uparrow:
            .specialKey(code: kVK_UpArrow, specialKey: .upArrow)
        case .down, .downarrow:
            .specialKey(code: kVK_DownArrow, specialKey: .downArrow)
        }
    }
}
