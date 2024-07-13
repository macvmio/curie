import Foundation

public final class TableRenderer {
    public enum Format {
        case text
        case json
    }

    public struct Config {
        public let columnPadding = 5
        public let format: Format

        public init(format: Format) {
            self.format = format
        }
    }

    public struct Content {
        public var headers: [String]
        public var rows: [[String]]

        public init(headers: [String], values: [[String]]) {
            self.headers = headers
            rows = values
        }
    }

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    public init() {}

    public func render(content: Content, config: Config) -> String {
        switch config.format {
        case .text:
            renderText(content: content, config: config)
        case .json:
            renderJson(content: content, config: config)
        }
    }

    // MARK: - Private

    private func renderJson(content: Content, config _: Config) -> String {
        let rawData = content.rows.reduce(into: [[String: String]]()) { acc, val in
            let dictionary = Dictionary(val.enumerated().map { (
                content.headers[$0].replacingOccurrences(of: " ", with: "_"),
                $1
            ) }) { first, _ in
                first
            }
            acc.append(dictionary)
        }

        guard let data = try? jsonEncoder.encode(rawData) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func renderText(content: Content, config: Config) -> String {
        let headersWidths: [Int] = content.headers.map(\.count)
        let valuesWidths: [Int] = content.rows.reduce(into: content.headers.map { _ in 0 }) { result, row in
            for item in row.enumerated() {
                result[item.offset] = max(result[item.offset], item.element.count)
            }
        }
        let widths: [Int] = (0 ..< max(headersWidths.count, valuesWidths.count)).map {
            max(headersWidths[$0], valuesWidths[$0])
        }

        var result = "\n"
        result.append(renderTextRow(content.headers.map { $0.uppercased() }, widths: widths, config: config))
        for row in content.rows {
            result.append(renderTextRow(row, widths: widths, config: config))
        }
        return result
    }

    private func renderTextRow(_ columns: [String], widths: [Int], config: Config) -> String {
        var result = ""
        for column in columns.enumerated() {
            result.append(column.element)
            result.append(space(widths[column.offset] - column.element.count))
            if column.offset < widths.count - 1 {
                result.append(space(config.columnPadding))
            }
        }
        result.append("\n")
        return result
    }

    private func space(_ columns: Int) -> String {
        (0 ..< columns).map { _ in " " }.joined()
    }
}
