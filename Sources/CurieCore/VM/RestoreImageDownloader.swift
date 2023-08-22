import CurieCommon
import Foundation

protocol RestoreImageDownloader {}

final class DefaultRestoreImageDownloader: RestoreImageDownloader {
    private let console: Console

    init(
        console: Console
    ) {
        self.console = console
    }
}
