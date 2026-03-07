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

public enum MouseSynthesisError: Error, CustomStringConvertible {
    case missingContentView
    case couldNotCreateEventFromMouseClick(MouseClick)

    public var description: String {
        switch self {
        case .missingContentView:
            "Could not synthesize mouse clicks: window is missing content view"
        case let .couldNotCreateEventFromMouseClick(mouseClick):
            "Could not synthesize mouse clicks: unable to create NSEvent from \(mouseClick)"
        }
    }
}
