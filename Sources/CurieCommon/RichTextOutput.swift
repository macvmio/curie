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
    private let blue: Style = .init("\u{001B}[34m", "\u{001B}[0m")
    private let lightGray: Style = .init("\u{001B}[37m", "\u{001B}[0m")
    private let darkGray: Style = .init("\u{001B}[90m", "\u{001B}[0m")
    private let white: Style = .init("\u{001B}[97m", "\u{001B}[0m")

    func string(from richText: RichText) -> String {
        richText.tokens.reduce(into: "") { acc, token in
            let styles = [
                color(from: token.attributes),
                style(from: token.attributes),
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
}
