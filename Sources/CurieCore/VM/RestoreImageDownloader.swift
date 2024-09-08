import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol RestoreImageDownloader {
    func download(to path: AbsolutePath) async throws
}

final class DefaultRestoreImageDownloader: NSObject, RestoreImageDownloader {
    private let restoreImageService: RestoreImageService
    private let httpClient: HTTPClient
    private let fileSystem: CurieCommon.FileSystem
    private let console: Console

    init(
        restoreImageService: RestoreImageService,
        httpClient: HTTPClient,
        fileSystem: CurieCommon.FileSystem,
        console: Console
    ) {
        self.restoreImageService = restoreImageService
        self.httpClient = httpClient
        self.fileSystem = fileSystem
        self.console = console
    }

    func download(to destinationPath: AbsolutePath) async throws {
        let restoreImage = try await restoreImageService.latestSupported()
        let (url, _) = try await httpClient.download(url: restoreImage.url, tracker: self)
        let path = try AbsolutePath(validating: url.path)
        try fileSystem.move(from: path, to: destinationPath)
        console.clear()
    }
}

extension DefaultRestoreImageDownloader: HTTPClientDownloadTracker {
    func httpClient(_: any HTTPClient, progress: HTTPClientDownloadProgress) {
        console.progress(
            prompt: "Downloading",
            progress: progress.progress,
            suffix: "\(progress.received)/\(progress.expected)"
        )
    }
}
