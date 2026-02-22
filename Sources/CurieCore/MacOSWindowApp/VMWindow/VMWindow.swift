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

class VMWindow: NSWindow {
    private let layeredViewController: LayeredViewController
    public let vmViewController: NSViewController
    public let auxiliaryViewController: NSViewController = NonResponderViewController()

    private var observer: AnyObject?

    public init(
        vmViewController: NSViewController,
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.vmViewController = vmViewController

        layeredViewController = LayeredViewController(
            mainViewController: vmViewController,
            overlayViewController: auxiliaryViewController
        )

        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        contentViewController = layeredViewController

        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }
    }

    public var viewToMakeFirstResponder: (VMWindow) -> NSView? = { _ in nil }

    override func update() {
        super.update()
        makeFirstResponder(viewToMakeFirstResponder(self))
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    public func viewForMakingVmScreenshot(
        includeClickVisualization: Bool
    ) -> NSView {
        if includeClickVisualization {
            layeredViewController.view
        } else {
            vmViewController.view
        }
    }

    private var eventsWaitingForAppActivation: [NSEvent] = []

    private func applicationDidBecomeActive() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for event in eventsWaitingForAppActivation {
                sendEvent(event)
            }
            eventsWaitingForAppActivation = []
        }
    }

    public func sendEventInActiveState(_ event: NSEvent) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
            eventsWaitingForAppActivation.append(event)
        } else {
            sendEvent(event)
        }
    }
}
