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
