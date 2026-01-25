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
import CurieCommon
import Foundation
import SwiftUI

// MARK: - Entry Point

let isServiceMode = CommandLine.arguments.contains("--service")
let isHelpMode = CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h")

if isHelpMode {
    print("""
    CurieAgent - Clipboard sync agent for macOS VMs

    Usage:
        CurieAgent              Launch installer UI
        CurieAgent --service    Run as clipboard sync daemon
        CurieAgent --help       Show this help message

    Description:
        This agent runs inside a macOS VM and synchronizes the clipboard
        with the host machine running curie.

    """)
} else if isServiceMode {
    // Run as daemon
    let console = DefaultConsole(output: StandardOutput.shared)
    let agent = AgentRunner(console: console)
    agent.run()
} else {
    // Launch installer UI
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {
        let contentView = InstallerView()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window?.title = "Curie Agent"
        window?.center()
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}
