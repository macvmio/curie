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

import AppKit
import Carbon.HIToolbox
import CurieCommon

extension KeyModifier {
    var nsEventModifierFlags: NSEvent.ModifierFlags {
        switch self {
        case .shift:
            return .shift
        case .command:
            return .command
        case .option:
            return .option
        case .control:
            return .control
        case .fn:
            return .function
        }
    }

    static func combinedModifierFlags(
        from keyModifiers: Set<KeyModifier>
    ) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        for modifier in keyModifiers {
            flags.insert(modifier.nsEventModifierFlags)
        }
        return flags
    }

    var keyCode: Int {
        switch self {
        case .shift:
            return kVK_Shift
        case .command:
            return kVK_Command
        case .option:
            return kVK_Option
        case .control:
            return kVK_Control
        case .fn:
            return kVK_Function
        }
    }
}
