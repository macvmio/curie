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
        public enum Row: Codable {
            case string(String)
            case memorySize(MemorySize)
            case date(Date)

            public func humanReadable(now: Date) -> String {
                switch self {
                case .string(let string):
                    return string
                case .memorySize(let memorySize):
                    return "\(memorySize)"
                case .date(let date):
                    return Self.humanDateFormatter.localizedString(for: date, relativeTo: now)
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let string):
                    try container.encode(string)
                case .memorySize(let memorySize):
                    try container.encode(memorySize)
                case .date(let date):
                    try container.encode(Self.jsonDateFormatter.string(from: date))
                }
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                do {
                    guard let date = Self.jsonDateFormatter.date(from: try container.decode(String.self)) else {
                        throw CoreError.generic("Cannot decode ISO8601 date")
                    }
                    self = .date(date)
                } catch {
                    do {
                        self = .memorySize(try container.decode(MemorySize.self))
                    } catch {
                        self = .string(try container.decode(String.self))
                    }
                }
            }

            private static let jsonDateFormatter = ISO8601DateFormatter()

            private static let humanDateFormatter: RelativeDateTimeFormatter = {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
        }

        public var headers: [String]
        public var rows: [[Row]]

        public init(headers: [String], values: [[Row]]) {
            self.headers = headers
            rows = values
        }
    }

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let wallClock: WallClock

    public init(
        wallClock: WallClock
    ) {
        self.wallClock = wallClock
    }

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
        let rawData = content.rows.reduce(into: [[String: Content.Row]]()) { acc, val in
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
                result[item.offset] = max(result[item.offset], item.element.humanReadable(now: wallClock.now()).count)
            }
        }
        let widths: [Int] = (0 ..< max(headersWidths.count, valuesWidths.count)).map {
            max(headersWidths[$0], valuesWidths[$0])
        }

        var result = "\n"
        result.append(
            renderTextRow(content.headers.map { Content.Row.string($0.uppercased()) }, widths: widths, config: config)
        )
        for row in content.rows {
            result.append(renderTextRow(row, widths: widths, config: config))
        }
        return result
    }

    private func renderTextRow(_ columns: [Content.Row], widths: [Int], config: Config) -> String {
        var result = ""
        for column in columns.enumerated() {
            result.append(column.element.humanReadable(now: wallClock.now()))
            result.append(space(widths[column.offset] - column.element.humanReadable(now: wallClock.now()).count))
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
