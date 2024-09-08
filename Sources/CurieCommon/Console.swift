//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
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

import Foundation

public protocol Console: AnyObject {
    var output: Output { get }
    var quiet: Bool { get set }

    func text(_ message: String)
    func text(_ message: String, always: Bool)
    func error(_ message: String)
    func clear()
    func progress(prompt: String, progress: Double)
    func progress(prompt: String, progress: Double, suffix: String?)
}

public final class DefaultConsole: Console {
    public let output: Output
    private let _quiet = Atomic<Bool>(value: false)

    public init(output: Output) {
        self.output = output
    }

    public func text(_ message: String) {
        text(message, always: false)
    }

    public func text(_ message: String, always: Bool = false) {
        if always || !quiet {
            output.write("\(message)\n", to: .stdout)
        }
    }

    public func error(_ message: String) {
        output.write("Error: \(message)\n", to: .stderr)
    }

    public func clear() {
        guard !output.redirected else {
            return
        }
        richTextOutput().write(.init(tokens: [
            .init(rawText: "\r", attributes: .none),
            .attributes(.function(.eraseFromCursorToEndOfLine)),
            .attributes(.mode(.makeCursorVisible)),
        ]))
    }

    public func progress(prompt: String, progress: Double) {
        self.progress(prompt: prompt, progress: progress, suffix: nil)
    }

    public func progress(prompt: String, progress: Double, suffix: String?) {
        if output.redirected {
            text("\(prompt) \(makePercentage(progress: progress))")
        } else {
            let blocksCount = 50
            let fullCount = Int(floor(progress * Double(blocksCount)))
            let emptyCount = blocksCount - fullCount
            let full = (0 ..< fullCount).map { _ in "=" }.joined()
            let empty = (0 ..< emptyCount).map { _ in " " }.joined()
            richTextOutput().write(.init(tokens: [
                .attributes(.mode(.makeCursorInvisible)),
                .init(rawText: prompt, attributes: .color(.blue)),
                .init(rawText: " ", attributes: .none),
                .init(rawText: "[", attributes: .color(.blue)),
                .init(rawText: "\(full)>\(empty)", attributes: .color(.blue)),
                .init(rawText: "]", attributes: .color(.blue)),
                .init(rawText: " ", attributes: .none),
            ] + makeSuffix(progress: progress, suffix: suffix)))
        }
    }

    public var quiet: Bool {
        get {
            _quiet.load()
        }
        set {
            _quiet.update(newValue)
        }
    }

    // MARK: - Private

    private func makeSuffix(progress: Double?, suffix: String?) -> [RichText.Token] {
        [
            .init(rawText: "\(suffix ?? makePercentage(progress: progress))", attributes: .color(.lightGray)),
            .attributes(.function(.eraseFromCursorToEndOfLine)),
            .init(rawText: "\r", attributes: .none),
        ]
    }

    private func makePercentage(progress: Double?) -> String {
        "\(String(format: "%.1f", (progress ?? 0) * 100))%"
    }
}

public extension Console {
    func richTextOutput(colorsEnabled: Bool = true) -> RichTextOutput {
        TerminalRichTextOutput(output: output, colorsEnabled: colorsEnabled)
    }
}
