import AppKit
import Foundation

public extension NSScreen {
    var dpi: CGSize {
        (deviceDescription[.resolution] as? CGSize) ?? .init(width: 72.0, height: 72.0)
    }
}
