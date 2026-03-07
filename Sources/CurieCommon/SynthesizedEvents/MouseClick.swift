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

public struct MouseClick: Codable {
    public static let defaultDelayBetweenClicks: TimeInterval = 0.1

    public var point: MouseCoordinate
    public var button: MouseButton
    public var clickCount: Int
    public var modifiers: Set<KeyModifier>
    public var delayAfter: TimeInterval

    public init(
        point: MouseCoordinate,
        button: MouseButton,
        clickCount: Int,
        modifiers: Set<KeyModifier>,
        delayAfter: TimeInterval
    ) {
        self.point = point
        self.button = button
        self.clickCount = max(1, clickCount)
        self.modifiers = modifiers
        self.delayAfter = max(0, delayAfter)
    }

    public static func single(
        button: MouseButton = .left,
        point: MouseCoordinate,
        modifiers: Set<KeyModifier> = [],
        delayAfter: TimeInterval = Self.defaultDelayBetweenClicks
    ) -> MouseClick {
        MouseClick(point: point, button: button, clickCount: 1, modifiers: modifiers, delayAfter: delayAfter)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        point = try container.decode(MouseCoordinate.self, forKey: .point)
        button = try container.decodeIfPresent(MouseButton.self, forKey: .button) ?? .left
        clickCount = try container.decodeIfPresent(Int.self, forKey: .clickCount) ?? 1
        modifiers = try container.decodeIfPresent(Set<KeyModifier>.self, forKey: .modifiers) ?? Set()
        delayAfter = try container.decodeIfPresent(TimeInterval.self, forKey: .delayAfter) ?? Self
            .defaultDelayBetweenClicks
    }

    enum CodingKeys: CodingKey {
        case point
        case button
        case clickCount
        case modifiers
        case delayAfter
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(point, forKey: .point)
        if button != .left {
            try container.encode(button, forKey: .button)
        }
        if clickCount != 1 {
            try container.encode(clickCount, forKey: .clickCount)
        }
        if !modifiers.isEmpty {
            try container.encode(modifiers, forKey: .modifiers)
        }
        if delayAfter != Self.defaultDelayBetweenClicks {
            try container.encode(delayAfter, forKey: .delayAfter)
        }
    }
}
