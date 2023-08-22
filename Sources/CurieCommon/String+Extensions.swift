import Foundation

extension String {
    func quoted() -> String {
        "\"\(self)\""
    }

    func containsWhitespaceAndNewlines() -> Bool {
        rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }
}

extension [String] {
    func command() -> String {
        map { $0.containsWhitespaceAndNewlines() ? $0.quoted() : $0 }.joined(separator: " ")
    }
}
