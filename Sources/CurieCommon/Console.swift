import Foundation

public protocol Console {
    var output: Output { get }

    func text(_ message: String)
    func error(_ message: String)
    func clear()
    func progress(prompt: String, progress: Double)
    func progress(prompt: String, progress: Double, suffix: String?)
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
        richTextOutput().write(.init(tokens: [
            .init(rawText: "\r", attributes: .none),
            .init(rawText: "", attributes: .function(.eraseFromCursorToEndOfLine)),
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
                .init(rawText: "» ", attributes: .color(.blue)),
                .init(rawText: prompt, attributes: .color(.blue)),
                .init(rawText: " ", attributes: .none),
                .init(rawText: "[", attributes: .color(.blue)),
                .init(rawText: "\(full)>\(empty)", attributes: .color(.blue)),
                .init(rawText: "]", attributes: .color(.blue)),
                .init(rawText: " ", attributes: .none),
            ] + makeSuffix(progress: progress, suffix: suffix)))
        }
    }

    private func makeSuffix(progress: Double?, suffix: String?) -> [RichText.Token] {
        [
            .init(rawText: "\(suffix ?? makePercentage(progress: progress))", attributes: .color(.lightGray)),
            .init(rawText: "", attributes: .function(.eraseFromCursorToEndOfLine)),
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
