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

public struct KeyboardInput: Codable {
    public static let defaultdelayAfterStrokes = 0.1

    public var content: KeyboardInputContent
    public var delayAfter: TimeInterval

    public init(
        content: KeyboardInputContent,
        delayAfter: TimeInterval = KeyboardInput.defaultdelayAfterStrokes
    ) {
        self.content = content
        self.delayAfter = delayAfter
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        content = try container.decode(KeyboardInputContent.self, forKey: .content)
        delayAfter = try container.decodeIfPresent(TimeInterval.self, forKey: .delayAfter) ?? KeyboardInput
            .defaultdelayAfterStrokes
    }

    enum CodingKeys: CodingKey {
        case content
        case delayAfter
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        if delayAfter != Self.defaultdelayAfterStrokes {
            try container.encode(delayAfter, forKey: .delayAfter)
        }
    }
}
