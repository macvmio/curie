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
import CoreGraphics
import CurieCommon
import Dispatch

extension VMWindow {
    /// Simulate mouse clicks inside a window. Points are relative to `contentView`.
    ///
    /// - Parameters:
    ///   - mouseClicks: Array of `MouseClick` items to perform in order.
    ///   - callbackQueue: thr queue where to schedule completion handler
    ///   - completion: callabck that will be called once all mouse clicks are performed
    public func synthesize(
        mouseClicks: [MouseClick],
        callbackQueue: DispatchQueue,
        completion: @escaping () -> Void
    ) throws {
        let eventGroup = DispatchGroup()
        defer {
            eventGroup.notify(queue: callbackQueue) {
                completion()
            }
        }

        let eventsWithTimeOffset = try getEventsWithTimeOffset(
            mouseClicks: mouseClicks
        )

        try schedule(
            eventsWithTimeOffset: eventsWithTimeOffset,
            eventGroup: eventGroup
        )
    }

    private func getEventsWithTimeOffset(
        mouseClicks: [MouseClick]
    ) throws -> [EventWithTimeOffset] {
        var eventsWithTimeOffset: [EventWithTimeOffset] = []
        var eventNumber = 0
        var accumulatedDelayAfter: TimeInterval = 0

        for mouseClick in mouseClicks {
            let downType: NSEvent.EventType = (mouseClick.button == .left) ? .leftMouseDown : .rightMouseDown
            let upType: NSEvent.EventType = (mouseClick.button == .left) ? .leftMouseUp : .rightMouseUp

            for eventType in [downType, upType] {
                try eventsWithTimeOffset.append(
                    EventWithTimeOffset(
                        event: createNsEvent(
                            nsEventType: eventType,
                            mouseClick: mouseClick,
                            eventNumber: eventNumber
                        ),
                        timeOffset: accumulatedDelayAfter,
                        nextEventAfter: accumulatedDelayAfter + mouseClick.delayAfter
                    )
                )
                eventNumber += 1
                accumulatedDelayAfter += mouseClick.delayAfter
            }
        }
        return eventsWithTimeOffset
    }

    private func schedule(
        eventsWithTimeOffset: [EventWithTimeOffset],
        eventGroup: DispatchGroup
    ) throws {
        DispatchQueue.main.async {
            for eventWithTimeOffset in eventsWithTimeOffset {
                eventGroup.enter()

                DispatchQueue.main.asyncAfter(deadline: .now() + eventWithTimeOffset.timeOffset) { [weak self] in
                    guard let self else {
                        eventGroup.leave()
                        return
                    }

                    self.sendEventInActiveState(eventWithTimeOffset.event)

                    let visualClickRect = eventWithTimeOffset.visualizationRect(
                        window: self,
                        view: auxiliaryViewController.view
                    )

                    let clickView = ClickView(frame: visualClickRect)
                    self.auxiliaryViewController.view.addSubview(clickView)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + eventWithTimeOffset.nextEventAfter) {
                        clickView.removeFromSuperview()
                        eventGroup.leave()
                    }
                }
            }
        }
    }

    private func createNsEvent(
        nsEventType: NSEvent.EventType,
        mouseClick: MouseClick,
        eventNumber: Int
    ) throws -> NSEvent {
        guard let contentView else {
            throw MouseSynthesisError.missingContentView
        }

        let locationInWindow: CGPoint = contentView.convert(mouseClick.point.cgPoint, to: nil)

        let event = NSEvent.mouseEvent(
            with: nsEventType,
            location: locationInWindow,
            modifierFlags: KeyModifier.combinedModifierFlags(
                from: mouseClick.modifiers
            ),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: windowNumber,
            context: nil,
            eventNumber: eventNumber,
            clickCount: mouseClick.clickCount,
            pressure: 1.0
        )
        guard let event else {
            throw MouseSynthesisError.couldNotCreateEventFromMouseClick(mouseClick)
        }
        return event
    }
}

private struct EventWithTimeOffset {
    public var event: NSEvent
    public var timeOffset: TimeInterval
    public var nextEventAfter: TimeInterval

    public var nextEventTimeOffset: TimeInterval {
        timeOffset + nextEventAfter
    }

    public func visualizationRect(window: NSWindow, view: NSView) -> NSRect {
        let center = event.locationInWindow
        return NSRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)
    }
}

extension MouseCoordinate {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

final class ClickView: NonResponderView {
    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.red.withAlphaComponent(0.5).cgColor
    }
}
