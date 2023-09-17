import ArgumentParser
import Foundation

enum Options {
    // swiftlint:disable:next type_name
    enum format {
        static var help: ArgumentHelp {
            "Format \"text\" or \"json\" (\"text\" by default)."
        }

        static var defaultValue: String {
            "text"
        }
    }
}
