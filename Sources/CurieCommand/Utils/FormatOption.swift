import CurieCommon
import CurieCore
import Foundation

protocol HasFormatOption {
    var format: String { get }
}

extension HasFormatOption {
    func parseFormatOption() throws -> OutputFormat {
        switch format {
        case "text":
            .text
        case "json":
            .json
        default:
            throw CoreError
                .generic("Unexpected format option (\"\(format)\"), please use \"text\" or \"json\"")
        }
    }
}
