import CurieCommon
import Foundation

protocol MacOSRestoreImageDownloader {}

final class DefaultMacOSRestoreImageDownloader: MacOSRestoreImageDownloader {
    private let console: Console

    init(
        console: Console
    ) {
        self.console = console
    }
}
