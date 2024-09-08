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

import CryptoKit
import Foundation

struct ImageID: Hashable, CustomStringConvertible, Codable {
    private let rawValue: String

    enum CodingKeys: CodingKey {
        case rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func make() -> ImageID {
        let uuid = UUID()
        let uuidData = uuid.uuidString.data(using: .utf8)!
        let hash = SHA256.hash(data: uuidData)
        let hashString = String(hash.compactMap { String(format: "%02x", $0) }.joined().prefix(12))
        return ImageID(rawValue: hashString)
    }

    var description: String {
        rawValue
    }
}

extension ImageID: Comparable {
    static func < (lhs: ImageID, rhs: ImageID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
