import Foundation

public protocol Console {
    var output: Output { get }

    func text(_ message: String)
    func error(_ message: String)
    func clear()
    func progress(prompt: String, progress: Double)
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

    public func clear() {
        guard !output.redirected else {
            return
        }
        let empty = (0 ..< 100).map { _ in " " }.joined()
        output.write("\r\(empty)\r")
    }

    public func progress(prompt: String, progress: Double) {
        let percentage = String(format: "%.1f", progress * 100)
        if output.redirected {
            text("\(prompt) \(percentage)%")
        } else {
            let blocksCount = 50
            let fullCount = Int(floor(progress * Double(blocksCount)))
            let emptyCount = blocksCount - fullCount
            let full = (0 ..< fullCount).map { _ in "=" }.joined()
            let empty = (0 ..< emptyCount).map { _ in " " }.joined()
            output.write("\(prompt) [\(full)>\(empty)] \(percentage)%\r")
        }
    }
}

public extension Console {
    func richTextOutput(colorsEnabled: Bool = true) -> RichTextOutput {
        TerminalRichTextOutput(output: output, colorsEnabled: colorsEnabled)
    }
}
