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

public protocol RichTextOutput {
    func write(_ text: RichText)
    func write(_ text: RichText, to stream: OutputStream)
}

public final class TerminalRichTextOutput: RichTextOutput {
    private let output: Output
    private let colorsEnabled: Bool
    private let converter = TerminalTextConverter()

    public init(output: Output, colorsEnabled: Bool = true) {
        self.output = output
        self.colorsEnabled = colorsEnabled && !output.redirected
    }

    public func write(_ text: RichText) {
        write(text, to: .stdout)
    }

    public func write(_ text: RichText, to _: OutputStream) {
        guard colorsEnabled else {
            output.write(text.plainString())
            return
        }
        output.write(converter.string(from: text))
    }
}

private final class TerminalTextConverter {
    struct Style {
        let begin: String
        let end: String

        init(_ begin: String, _ end: String) {
            self.begin = begin
            self.end = end
        }

        func apply(on string: String) -> String {
            "\(begin)\(string)\(end)"
        }
    }

    // Styles
    private let bold: Style = .init("\u{001B}[1m", "\u{001B}[22m")
    private let dim: Style = .init("\u{001B}[2m", "\u{001B}[22m")
    private let italic: Style = .init("\u{001B}[3m", "\u{001B}[23m")
    private let underline: Style = .init("\u{001B}[4m", "\u{001B}[24m")

    // Colors
    private let none: Style = .init("", "")
    private let black: Style = .init("\u{001B}[30m", "\u{001B}[0m")
    private let red: Style = .init("\u{001B}[31m", "\u{001B}[0m")
    private let green: Style = .init("\u{001B}[32m", "\u{001B}[0m")
    private let yellow: Style = .init("\u{001B}[33m", "\u{001B}[0m")
    private let lightBlue: Style = .init("\u{001B}[94m", "\u{001B}[0m")
    private let blue: Style = .init("\u{001B}[34m", "\u{001B}[0m")
    private let lightGray: Style = .init("\u{001B}[37m", "\u{001B}[0m")
    private let darkGray: Style = .init("\u{001B}[90m", "\u{001B}[0m")
    private let white: Style = .init("\u{001B}[97m", "\u{001B}[0m")

    // Functions
    private let eraseFromCursorToEndOfLine: Style = .init("\u{001B}[0K", "")
    private let eraseStartOfLineToCursor: Style = .init("\u{001B}[1K", "")

    // Modes
    private let makeCursorInvisible: Style = .init("\u{001B}[?25l", "")
    private let makeCursorVisible: Style = .init("\u{001B}[?25h", "")

    func string(from richText: RichText) -> String {
        richText.tokens.reduce(into: "") { acc, token in
            let styles = [
                color(from: token.attributes),
                style(from: token.attributes),
                function(from: token.attributes),
                mode(from: token.attributes),
            ]
            let string: String = styles.reduce(into: token.rawText) { acc, value in
                acc = value.apply(on: acc)
            }
            acc.append(string)
        }
    }

    // MARK: - Private

    private func style(from attributes: RichText.Attributes) -> Style {
        guard let style = attributes.style else {
            return none
        }
        switch style {
        case .bold:
            return bold
        case .dim:
            return dim
        case .italic:
            return italic
        case .underline:
            return underline
        }
    }

    private func color(from attributes: RichText.Attributes) -> Style {
        guard let color = attributes.color else {
            return none
        }
        switch color {
        case .black:
            return black
        case .red:
            return red
        case .green:
            return green
        case .yellow:
            return yellow
        case .lightBlue:
            return lightBlue
        case .blue:
            return blue
        case .lightGray:
            return lightGray
        case .darkGray:
            return darkGray
        case .white:
            return white
        }
    }

    private func function(from attributes: RichText.Attributes) -> Style {
        guard let function = attributes.function else {
            return none
        }
        switch function {
        case .eraseFromCursorToEndOfLine:
            return eraseFromCursorToEndOfLine
        case .eraseStartOfLineToCursor:
            return eraseStartOfLineToCursor
        }
    }

    private func mode(from attributes: RichText.Attributes) -> Style {
        guard let mode = attributes.mode else {
            return none
        }
        switch mode {
        case .makeCursorInvisible:
            return makeCursorInvisible
        case .makeCursorVisible:
            return makeCursorVisible
        }
    }
}
