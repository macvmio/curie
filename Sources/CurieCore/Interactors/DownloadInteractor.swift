//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
    func execute(context: DownloadInteractorContext) throws
}

public final class DefaultDownloadInteractor: AsyncInteractor {
    typealias Context = DownloadInteractorContext

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

    public func execute(context: DownloadInteractorContext, runLoop _: any RunLoopAccessor) async throws {
        guard let path = try? fileSystem.absolutePath(from: context.path) else {
            throw CoreError.generic("Invalid path \"\(context.path)\"")
        }
        guard !fileSystem.exists(at: path) else {
            throw CoreError.generic("File already exists at path \"\(context.path)\"")
        }
        let restoreImage = try await restoreImageService.latestSupported()
        let (url, _) = try await httpClient.download(url: restoreImage.url, tracker: self)
        let fromPath = try AbsolutePath(validating: url.path)
        try fileSystem.move(from: fromPath, to: path)
        console.clear()
    }
}

extension DefaultDownloadInteractor: HTTPClientDownloadTracker {
    public func httpClient(_: any HTTPClient, progress: HTTPClientDownloadProgress) {
        console.progress(
            prompt: "Downloading",
            progress: progress.progress,
            suffix: "\(progress.received)/\(progress.expected)"
        )
    }
}
