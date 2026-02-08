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
