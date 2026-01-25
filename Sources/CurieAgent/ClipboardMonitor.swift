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
import Foundation

protocol ClipboardMonitorDelegate: AnyObject {
    func clipboardMonitor(_ monitor: ClipboardMonitor, didDetectChange content: ClipboardContent)
}

final class ClipboardMonitor {
    weak var delegate: ClipboardMonitorDelegate?

    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let pollInterval: TimeInterval = 0.5

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func readClipboard() -> ClipboardContent? {
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

    func writeClipboard(content: ClipboardContent) {
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

    // MARK: - Private

    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }
        lastChangeCount = currentChangeCount

        if let content = readClipboard() {
            delegate?.clipboardMonitor(self, didDetectChange: content)
        }
    }
}
