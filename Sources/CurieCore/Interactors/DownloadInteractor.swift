import Combine
import CurieCommon
import Foundation
import TSCBasic

public struct DownloadInteractorContext {
    public var path: String

    public init(path: String) {
        self.path = path
    }
}

public protocol DownloadInteractor {
    func execute(with context: DownloadInteractorContext) throws
}

public final class DefaultDownloadInteractor: DownloadInteractor {
    private let downloader: RestoreImageDownloader
    private let fileSystem: CurieCommon.FileSystem
    private let system: System
    private let console: Console

    init(
        downloader: RestoreImageDownloader,
        fileSystem: CurieCommon.FileSystem,
        system: System,
        console: Console
    ) {
        self.downloader = downloader
        self.fileSystem = fileSystem
        self.system = system
        self.console = console
    }

    public func execute(with context: DownloadInteractorContext) throws {
        guard let path = try? AbsolutePath(validating: context.path) else {
            throw CoreError.generic("Invalid path \"\(context.path)\"")
        }
        guard !fileSystem.exists(at: path) else {
            throw CoreError.generic("File already exists at path \"\(context.path)\"")
        }

        downloader.download(to: path, completion: exit)

        system.keepAliveWithSIGINTEventHandler { [console] exit in
            console.text("Download has been cancelled")
            exit(0)
        }
    }
}
