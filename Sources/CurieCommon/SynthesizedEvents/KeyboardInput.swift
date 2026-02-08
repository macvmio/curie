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

/// Human-friendly variants of various keys, mostly to make JSON user firendly.
public enum KeyboardKey: String, Codable {
    case `return`, enter
    case escape, esc
    case tab
    case delete, deletebackward, backspace
    case deleteforward, forwarddelete
    case space, spacebar
    case left, leftarrow
    case right, rightarrow
    case up, uparrow // swiftlint:disable:this identifier_name
    case down, downarrow
}

public enum KeyPhase: String, Codable {
    /// Down alone is generally used to enable key modifier (e.g. shift + <other key while shift is pressed>)
    /// The event flow would be:  down (for shift) -> press (for other keys) -> up (for shift)
    case down

    /// Up alone is used to release key modifier
    case up // swiftlint:disable:this identifier_name

    /// Regular key press (down and then up)
    case press
}
