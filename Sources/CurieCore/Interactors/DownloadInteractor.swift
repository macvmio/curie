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
    private let runLoop: CurieCommon.RunLoop
    private let console: Console

    init(
        downloader: RestoreImageDownloader,
        fileSystem: CurieCommon.FileSystem,
        runLoop: CurieCommon.RunLoop,
        console: Console
    ) {
        self.downloader = downloader
        self.fileSystem = fileSystem
        self.runLoop = runLoop
        self.console = console
    }

    public func execute(with context: DownloadInteractorContext) throws {
        guard let path = try? fileSystem.absolutePath(from: context.path) else {
            throw CoreError.generic("Invalid path \"\(context.path)\"")
        }
        guard !fileSystem.exists(at: path) else {
            throw CoreError.generic("File already exists at path \"\(context.path)\"")
        }

        try runLoop.run { [self] _ in
            try await downloader.download(to: path)
        }
    }
}
