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
import Foundation

final class AgentRunner {
    private let console: Console
    private let connection: HostConnection
    private let clipboardMonitor = ClipboardMonitor()
    private var sequenceNumber: UInt32 = 0
    private var isConnected = false

    init(console: Console) {
        self.console = console
        connection = HostConnection(console: console)
    }

    func run() {
        console.text("Starting clipboard sync agent")
        console.text("Connecting to host on port \(ClipboardConstants.port)...")

        connection.delegate = self
        clipboardMonitor.delegate = self

        connection.connect()
        clipboardMonitor.start()

        // Run the main run loop
        RunLoop.main.run()
    }

    // MARK: - Private

    private func sendClipboardToHost() {
        guard isConnected else { return }

        guard let content = clipboardMonitor.readClipboard() else { return }

        sequenceNumber += 1
        guard let message = ClipboardMessage.clipboardData(sequenceNumber: sequenceNumber, content: content) else {
            console.error("Failed to encode clipboard data")
            return
        }

        connection.send(message)
    }
}

extension AgentRunner: HostConnectionDelegate {
    func connectionDidConnect(_: HostConnection) {
        console.text("Connected to host")
        isConnected = true

        // Send current clipboard state to host
        sendClipboardToHost()
    }

    func connectionDidDisconnect(_: HostConnection) {
        console.text("Disconnected from host, will retry...")
        isConnected = false
    }

    func connection(_: HostConnection, didReceive message: ClipboardMessage) {
        switch message.type {
        case .clipboardChanged:
            // Host clipboard changed, request the data
            sequenceNumber += 1
            let request = ClipboardMessage.clipboardRequest(sequenceNumber: sequenceNumber)
            connection.send(request)

        case .clipboardData:
            // Received clipboard data from host
            if let content = message.parseClipboardContent() {
                clipboardMonitor.writeClipboard(content: content)
            }

        case .clipboardRequest:
            // Host is requesting our clipboard
            sendClipboardToHost()

        case .ping:
            // Respond to ping
            let pong = ClipboardMessage.pong(sequenceNumber: message.sequenceNumber)
            connection.send(pong)

        case .pong:
            // Received pong response
            break
        }
    }
}

extension AgentRunner: ClipboardMonitorDelegate {
    func clipboardMonitor(_: ClipboardMonitor, didDetectChange content: ClipboardContent) {
        guard isConnected else { return }

        sequenceNumber += 1
        guard let message = ClipboardMessage.clipboardData(sequenceNumber: sequenceNumber, content: content) else {
            console.error("Failed to encode clipboard data")
            return
        }

        connection.send(message)
    }
}
