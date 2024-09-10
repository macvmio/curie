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

import CurieCommon
import Foundation
import TSCBasic

public struct BuildParameters {
    var ipwsPath: String
    var reference: String
    var diskSize: String?
    var configPath: String?

    public init(
        ipwsPath: String,
        reference: String,
        diskSize: String?,
        configPath: String?
    ) {
        self.ipwsPath = ipwsPath
        self.reference = reference
        self.diskSize = diskSize
        self.configPath = configPath
    }
}

final class BuildInteractor: AsyncInteractor {
    private let configurator: VMConfigurator
    private let installer: VMInstaller
    private let imageCache: ImageCache
    private let fileSystem: CurieCommon.FileSystem
    private let console: Console

    init(
        configurator: VMConfigurator,
        installer: VMInstaller,
        imageCache: ImageCache,
        fileSystem: CurieCommon.FileSystem,
        console: Console
    ) {
        self.configurator = configurator
        self.installer = installer
        self.imageCache = imageCache
        self.fileSystem = fileSystem
        self.console = console
    }

    func execute(parameters: BuildParameters) async throws {
        let reference = try imageCache.makeImageReference(parameters.reference)
        let bundlePath = try imageCache.path(to: reference)
        let bundle = VMBundle(path: bundlePath)

        // Get restore image path
        let restoreImagePath = prepareRestoreImagePath(path: parameters.ipwsPath)

        // Create VM bundle
        try await configurator.createVM(with: bundle, spec: .init(
            reference: reference,
            restoreImagePath: restoreImagePath,
            diskSize: prepareDiskSize(parameters: parameters),
            configPath: prepareConfigPath(parameters: parameters)
        ))

        // Load VM
        let vm = try configurator.loadVM(with: bundle, overrideConfig: nil)

        // Install VM image
        try await installer.install(vm: vm, restoreImagePath: restoreImagePath)
    }

    // MARK: - Private

    private func prepareDiskSize(parameters: BuildParameters) throws -> MemorySize {
        guard let diskSize = parameters.diskSize else {
            return Constants.defaultDiskSize
        }
        guard let diskSize = MemorySize(string: diskSize) else {
            throw CoreError(message: "Invalid disk size", metadata: ["SIZE": diskSize])
        }
        return diskSize
    }

    private func prepareConfigPath(parameters: BuildParameters) -> AbsolutePath? {
        parameters.configPath.map(fileSystem.absolutePath(from:))
    }

    private func prepareRestoreImagePath(path: String) -> AbsolutePath {
        fileSystem.absolutePath(from: path)
    }
}
