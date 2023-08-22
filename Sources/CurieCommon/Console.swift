import Foundation

public protocol Console {
    var output: Output { get }

    func text(_ message: String)
    func error(_ message: String)
}

public final class DefaultConsole: Console {
    public let output: Output

    public init(output: Output) {
        self.output = output
    }

    public func text(_ message: String) {
        output.write("\(message)\n", to: .stdout)
    }

    public func error(_ message: String) {
        output.write("Error: \(message)\n", to: .stderr)
    }
}

public extension Console {
    func richTextOutput(colorsEnabled: Bool = true) -> RichTextOutput {
        TerminalRichTextOutput(output: output, colorsEnabled: colorsEnabled)
    }
}
