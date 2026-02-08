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

public enum KeyboardInputContent: Codable {
    /// Single key with modifiers
    case key(KeyboardKey, Set<KeyModifier> = [], KeyPhase = .press)

    /// Generates key strokes to match given text
    case text(String)

    enum CodingKeys: String, CodingKey {
        case text
        case key
        case modifiers
        case phase
    }

    public init(from decoder: any Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self = try .text(container.decode(String.self))
        } catch {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self = try .key(
                container.decode(KeyboardKey.self, forKey: .key),
                container.decode(Set<KeyModifier>.self, forKey: .modifiers),
                container.decode(KeyPhase.self, forKey: .phase)
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .key(keyboardKey, keyModifiers, keyPhase):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(keyboardKey.rawValue, forKey: .key)
            try container.encode(keyModifiers, forKey: .modifiers)
            try container.encode(keyPhase, forKey: .phase)
        case let .text(string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        }
    }
}
