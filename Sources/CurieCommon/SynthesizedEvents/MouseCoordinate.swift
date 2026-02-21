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

import Foundation

public struct MouseCoordinate: Codable {
    // swiftlint:disable:next identifier_name
    public var x: Int
    // swiftlint:disable:next identifier_name
    public var y: Int

    // swiftlint:disable:next identifier_name
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public struct DecodeError: Error, CustomStringConvertible {
        public var stringValue: String
        public var description: String {
            "Unable to convert string value to MouseCoordinate: \(stringValue)"
        }
    }

    public static func from(stringValue: String) throws -> MouseCoordinate {
        let components: [Int] = stringValue.split(separator: ",")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .compactMap {
                Int($0)
            }
        guard components.count == 2 else {
            throw DecodeError(stringValue: stringValue)
        }
        return MouseCoordinate(x: components[0], y: components[1])
    }

    public var stringValue: String {
        "\(x),\(y)"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self = try MouseCoordinate.from(stringValue: stringValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
