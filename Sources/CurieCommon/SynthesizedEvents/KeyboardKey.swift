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

/// Human-friendly variants of various keys, mostly to make JSON user friendly.
public enum KeyboardKey: String, Codable {
    case `return`, enter
    case escape, esc
    case tab
    case delete, deletebackward, backspace
    case deleteforward, forwarddelete
    case space, spacebar
    case left, leftarrow
    case right, rightarrow
    case up, uparrow // swiftlint:disable:this identifier_name
    case down, downarrow
}
