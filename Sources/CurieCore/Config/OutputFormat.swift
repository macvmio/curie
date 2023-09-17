import CurieCommon
import Foundation

public enum OutputFormat {
    case text
    case json
}

extension OutputFormat {
    func rendererFormat() -> TableRenderer.Format {
        switch self {
        case .text:
            return .text
        case .json:
            return .json
        }
    }
}
