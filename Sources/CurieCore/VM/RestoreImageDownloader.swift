import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol RestoreImageDownloader {
    func download(to path: AbsolutePath, completion: @escaping (Int32) -> Never)
}

final class DefaultRestoreImageDownloader: NSObject, RestoreImageDownloader {
    private let fileSystem: CurieCommon.FileSystem
    private let console: Console
    private let urlSession = URLSession.shared

    private var downloadObserver: NSKeyValueObservation?

    init(fileSystem: CurieCommon.FileSystem, console: Console) {
        self.fileSystem = fileSystem
        self.console = console
    }

    func download(to path: AbsolutePath, completion: @escaping (Int32) -> Never) {
        VZMacOSRestoreImage.fetchLatestSupported { [self] (result: Result<VZMacOSRestoreImage, Error>) in
            switch result {
            case let .failure(error):
                fatalError(error.localizedDescription)
            case let .success(restoreImage):
                downloadRestoreImage(
                    restoreImage: restoreImage,
                    path: path,
                    completion: completion
                )
            }
        }
    }

    // MARK: - Private

    private func downloadRestoreImage(
        restoreImage: VZMacOSRestoreImage,
        path: AbsolutePath,
        completion: @escaping (Int32) -> Never
    ) {
        let downloadTask = urlSession
            .downloadTask(with: restoreImage.url) { [fileSystem, console] localURL, _, error in
                if let error {
                    console.error("Download failed - \(error.localizedDescription)")
                    completion(1)
                }

                guard let localPath = try? localURL.map({ try AbsolutePath(validating: $0.path) }) else {
                    console.error("Failed to locate the downloaded file")
                    completion(1)
                }

                console.clear()

                do {
                    try fileSystem.move(from: localPath, to: path)
                    console.text("Download completed")
                    completion(0)
                } catch {
                    console.error(error.localizedDescription)
                    completion(1)
                }
            }

        downloadObserver = downloadTask.progress.observe(\.fractionCompleted, options: [
            .initial,
            .new,
        ]) { [console] _, change in
            let receivedSize = MemorySize(bytes: UInt64(downloadTask.countOfBytesReceived))
            let expectedToReceivesize = MemorySize(bytes: UInt64(downloadTask.countOfBytesExpectedToReceive))
            let progress = "\(receivedSize)/\(expectedToReceivesize)"
            let suffix = "\(progress)"
            console.progress(
                prompt: "Downloading...",
                progress: change.newValue ?? 0.0,
                suffix: suffix
            )
        }
        downloadTask.resume()
    }
}
