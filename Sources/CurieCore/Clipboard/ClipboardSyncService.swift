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
import Virtualization

public protocol ClipboardSyncService {
    func start(socketDevice: VZVirtioSocketDevice)
    func stop()
}

public final class DefaultClipboardSyncService: NSObject, ClipboardSyncService {
    private let console: Console
    private var socketDevice: VZVirtioSocketDevice?
    private var connection: VZVirtioSocketConnection?
    private var listener: VZVirtioSocketListener?

    private var lastChangeCount: Int = 0
    private var sequenceNumber: UInt32 = 0
    private var clipboardMonitorTimer: Timer?
    private var receiveBuffer = Data()

    private let syncQueue = DispatchQueue(label: "com.curie.clipboard-sync")
    private var readSource: DispatchSourceRead?

    public init(console: Console) {
        self.console = console
        super.init()
    }

    public func start(socketDevice: VZVirtioSocketDevice) {
        self.socketDevice = socketDevice

        let listener = VZVirtioSocketListener()
        listener.delegate = self
        self.listener = listener

        socketDevice.setSocketListener(listener, forPort: ClipboardConstants.port)
        console.text("Agent service started on port \(ClipboardConstants.port)")

        lastChangeCount = NSPasteboard.general.changeCount
        startClipboardMonitor()
    }

    public func stop() {
        stopClipboardMonitor()
        cleanupConnection()

        if let socketDevice {
            socketDevice.removeSocketListener(forPort: ClipboardConstants.port)
        }
        listener = nil
        socketDevice = nil
        console.text("Agent service stopped")
    }

    // MARK: - Private

    private func startClipboardMonitor() {
        clipboardMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }

    private func stopClipboardMonitor() {
        clipboardMonitorTimer?.invalidate()
        clipboardMonitorTimer = nil
    }

    private func checkClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }
        lastChangeCount = currentChangeCount
        sendClipboardToGuest()
    }

    private func sendClipboardToGuest() {
        guard let content = readHostClipboard() else {
            return
        }

        sequenceNumber += 1
        guard let message = ClipboardMessage.clipboardData(sequenceNumber: sequenceNumber, content: content) else {
            console.text("Failed to encode clipboard data")
            return
        }

        sendMessage(message)
    }

    private func readHostClipboard() -> ClipboardContent? {
        let pasteboard = NSPasteboard.general

        if let string = pasteboard.string(forType: .string) {
            return ClipboardContent(
                type: .plainText,
                data: Data(string.utf8),
                changeCount: pasteboard.changeCount
            )
        }

        if let data = pasteboard.data(forType: .png) {
            return ClipboardContent(
                type: .png,
                data: data,
                changeCount: pasteboard.changeCount
            )
        }

        if let data = pasteboard.data(forType: .tiff) {
            return ClipboardContent(
                type: .tiff,
                data: data,
                changeCount: pasteboard.changeCount
            )
        }

        if let data = pasteboard.data(forType: .rtf) {
            return ClipboardContent(
                type: .rtf,
                data: data,
                changeCount: pasteboard.changeCount
            )
        }

        return nil
    }

    private func writeHostClipboard(content: ClipboardContent) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch content.type {
        case .plainText:
            if let string = String(data: content.data, encoding: .utf8) {
                pasteboard.setString(string, forType: .string)
            }
        case .png:
            pasteboard.setData(content.data, forType: .png)
        case .tiff:
            pasteboard.setData(content.data, forType: .tiff)
        case .rtf:
            pasteboard.setData(content.data, forType: .rtf)
        }

        lastChangeCount = pasteboard.changeCount
    }

    private func sendMessage(_ message: ClipboardMessage) {
        guard let connection else {
            return
        }

        let data = message.encode()
        let fileDescriptor = connection.fileDescriptor
        let bytesWritten = data.withUnsafeBytes { buffer -> Int in
            guard let baseAddress = buffer.baseAddress else { return -1 }
            return write(fileDescriptor, baseAddress, buffer.count)
        }

        if bytesWritten < 0 {
            let errorCode = errno
            console.text("Agent write error \(errorCode)")
        }
    }

    private func handleReceivedData(_ data: Data) {
        receiveBuffer.append(data)

        while let (message, bytesConsumed) = ClipboardMessage.decode(from: receiveBuffer) {
            receiveBuffer.removeFirst(bytesConsumed)
            handleMessage(message)
        }
    }

    private func handleMessage(_ message: ClipboardMessage) {
        switch message.type {
        case .clipboardChanged:
            sequenceNumber += 1
            let request = ClipboardMessage.clipboardRequest(sequenceNumber: sequenceNumber)
            sendMessage(request)

        case .clipboardData:
            if let content = message.parseClipboardContent() {
                DispatchQueue.main.async { [weak self] in
                    self?.writeHostClipboard(content: content)
                }
            }

        case .clipboardRequest:
            sendClipboardToGuest()

        case .ping:
            let pong = ClipboardMessage.pong(sequenceNumber: message.sequenceNumber)
            sendMessage(pong)

        case .pong:
            break
        }
    }

    private func startReadingFromConnection(_ connection: VZVirtioSocketConnection) {
        let fileDescriptor = connection.fileDescriptor
        readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: syncQueue)

        readSource?.setEventHandler { [weak self] in
            guard let self else { return }
            // Check if already cleaning up
            guard readSource != nil else { return }

            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(fileDescriptor, &buffer, buffer.count)

            if bytesRead < 0 {
                let errorCode = errno
                // Clear readSource to prevent more event handling
                let source = readSource
                readSource = nil
                source?.cancel()
                DispatchQueue.main.async {
                    self.console.text("Agent read error \(errorCode)")
                    self.cleanupConnection()
                }
                return
            }

            if bytesRead == 0 {
                // Clear readSource to prevent more event handling
                let source = readSource
                readSource = nil
                source?.cancel()
                DispatchQueue.main.async {
                    self.console.text("Agent disconnected")
                    self.cleanupConnection()
                }
                return
            }

            let data = Data(buffer[0 ..< bytesRead])
            handleReceivedData(data)
        }

        readSource?.resume()
    }

    private func cleanupConnection() {
        // Cancel read source if not already done
        if let source = readSource {
            readSource = nil
            source.cancel()
        }

        connection = nil
        receiveBuffer.removeAll()
    }
}

extension DefaultClipboardSyncService: VZVirtioSocketListenerDelegate {
    public func listener(
        _: VZVirtioSocketListener,
        shouldAcceptNewConnection connection: VZVirtioSocketConnection,
        from _: VZVirtioSocketDevice
    ) -> Bool {
        if self.connection != nil {
            console.text("Agent rejecting new connection, already connected")
            return false
        }

        self.connection = connection
        console.text("Agent connected")

        startReadingFromConnection(connection)
        sendClipboardToGuest()

        return true
    }
}
