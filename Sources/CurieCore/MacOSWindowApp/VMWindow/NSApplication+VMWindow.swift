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

enum VMWindowError: Error, CustomStringConvertible {
    case missingWindow
    case unexpectedWindowCount(Int)

    var description: String {
        switch self {
        case .missingWindow:
            "No VM window found."
        case let .unexpectedWindowCount(count):
            "Unexpected number of VM windows: \(count)"
        }
    }
}

extension NSApplication {
    var vmWindows: [VMWindow] {
        NSApp.windows.compactMap { $0 as? VMWindow }
    }

    func getSingleVmWindow() throws -> VMWindow {
        let vmWindows = vmWindows
        if vmWindows.isEmpty {
            throw VMWindowError.missingWindow
        }
        guard vmWindows.count == 1, let vmWindow = vmWindows.first else {
            throw VMWindowError.unexpectedWindowCount(vmWindows.count)
        }
        return vmWindow
    }
}
