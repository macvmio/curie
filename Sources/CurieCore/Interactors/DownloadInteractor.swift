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

public struct DownloadParameters {
    public var path: String

    public init(path: String) {
        self.path = path
    }
}

final class DownloadInteractor: AsyncInteractor {
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

    func execute(parameters: DownloadParameters, runLoop _: any RunLoopAccessor) async throws {
        guard let path = try? fileSystem.absolutePath(from: parameters.path) else {
            throw CoreError(message: "Invalid path", metadata: ["PATH": parameters.path])
        }
        guard !fileSystem.isDirectory(at: path) else {
            throw CoreError(message: "Directory already exists at path", metadata: ["PATH": parameters.path])
        }
        guard !fileSystem.exists(at: path) else {
            throw CoreError(message: "File already exists at path", metadata: ["PATH": parameters.path])
        }
        let restoreImage = try await restoreImageService.latestSupported()
        guard restoreImage.isSupported else {
            throw CoreError(message: "Latest image is not supported", metadata: [
                "BUILD_VERSION": restoreImage.buildVersion,
                "OS_VERSION": restoreImage.operatingSystemVersion,
            ])
        }
        console
            .text("Will download restore image (\(restoreImage.buildVersion), \(restoreImage.operatingSystemVersion))")
        let (url, _) = try await httpClient.download(url: restoreImage.url, tracker: self)
        let fromPath = try AbsolutePath(validating: url.path)
        try fileSystem.move(from: fromPath, to: path)
        console.clear()
        console.text("Download completed")
    }
}

extension DownloadInteractor: HTTPClientDownloadTracker {
    public func httpClient(_: any HTTPClient, progress: HTTPClientDownloadProgress) {
        console.progress(
            prompt: "Downloading",
            progress: progress.progress,
            suffix: "\(progress.received)/\(progress.expected)"
        )
    }
}
