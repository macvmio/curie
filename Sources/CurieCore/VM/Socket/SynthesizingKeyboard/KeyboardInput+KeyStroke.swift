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

extension KeyboardInput {
    func allKeyStrokes() throws -> [KeyStroke] {
        switch content {
        case let .text(string):
            return try KeyStroke.keystrokesForTypingString(
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
