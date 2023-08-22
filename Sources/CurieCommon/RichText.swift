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
        case blue
        case lightGray
        case darkGray
        case white
    }

    public class Attributes {
        let style: Style?
        let color: Color?

        static let none = Attributes(
            style: nil,
            color: nil
        )

        private init(
            style: Style?,
            color: Color?
        ) {
            self.style = style
            self.color = color
        }

        static func style(_ style: Style) -> Attributes {
            Attributes(
                style: style,
                color: nil
            )
        }

        public static func color(_ color: Color) -> Attributes {
            Attributes(
                style: nil,
                color: color
            )
        }

        public static func + (lhs: Attributes, rhs: Attributes) -> Attributes {
            Attributes(
                style: rhs.style ?? lhs.style,
                color: rhs.color ?? lhs.color
            )
        }
    }

    struct Token {
        let rawText: String
        let attributes: Attributes

        static func plain(_ string: String) -> Token {
            Token(rawText: string, attributes: .none)
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
