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

public struct RichText: ExpressibleByStringLiteral {
    public enum Style {
        case bold
        case dim
        case italic
        case underline
    }

    public enum Color {
        case black
        case red
        case green
        case yellow
        case lightBlue
        case blue
        case lightGray
        case darkGray
        case white
    }

    public enum Function {
        case eraseFromCursorToEndOfLine
        case eraseStartOfLineToCursor
    }

    public enum Mode {
        case makeCursorInvisible
        case makeCursorVisible
    }

    public class Attributes {
        let style: Style?
        let color: Color?
        let function: Function?
        let mode: Mode?

        static let none = Attributes(
            style: nil,
            color: nil,
            function: nil,
            mode: nil
        )

        private init(
            style: Style?,
            color: Color?,
            function: Function?,
            mode: Mode?
        ) {
            self.style = style
            self.color = color
            self.function = function
            self.mode = mode
        }

        static func style(_ style: Style) -> Attributes {
            Attributes(
                style: style,
                color: nil,
                function: nil,
                mode: nil
            )
        }

        public static func color(_ color: Color) -> Attributes {
            Attributes(
                style: nil,
                color: color,
                function: nil,
                mode: nil
            )
        }

        public static func function(_ function: Function) -> Attributes {
            Attributes(
                style: nil,
                color: nil,
                function: function,
                mode: nil
            )
        }

        public static func mode(_ mode: Mode) -> Attributes {
            Attributes(
                style: nil,
                color: nil,
                function: nil,
                mode: mode
            )
        }

        public static func + (lhs: Attributes, rhs: Attributes) -> Attributes {
            Attributes(
                style: rhs.style ?? lhs.style,
                color: rhs.color ?? lhs.color,
                function: rhs.function ?? lhs.function,
                mode: rhs.mode ?? lhs.mode
            )
        }
    }

    struct Token {
        let rawText: String
        let attributes: Attributes

        static func plain(_ string: String) -> Token {
            Token(rawText: string, attributes: .none)
        }

        static func attributes(_ attributes: Attributes) -> Token {
            Token(rawText: "", attributes: attributes)
        }
    }

    let tokens: [Token]

    // MARK: - Init

    public init(stringLiteral rawValue: String) {
        tokens = [.plain(rawValue)]
    }

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    // MARK: - Public

    public func plainString() -> String {
        tokens.reduce(into: "") { acc, value in
            acc.append(value.rawText)
        }
    }

    public static var newLine: RichText {
        RichText(stringLiteral: "\n")
    }

    public static func text(_ string: String, _ attributes: Attributes) -> RichText {
        RichText(tokens: [.init(rawText: string, attributes: attributes)])
    }

    public static func + (lhs: RichText, rhs: RichText) -> RichText {
        RichText(tokens: lhs.tokens + rhs.tokens)
    }
}
