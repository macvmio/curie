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
import CurieCommonMocks
@testable import CurieCore
import CurieCoreMocks
import Foundation
import SCInject

final class InteractorsTestsEnvironment {
    let restoreImageService = MockRestoreImageService()
    let directory: TemporaryDirectory
    let system = MockSystem()
    let fileSystem: FileSystem
    let httpClient = MockHTTPClient()
    let console = MockConsole()
    let runLoop = DefaultRunLoop(interval: .short)

    let fileManager = FileManager.default

    init() {
        let directory = try! TemporaryDirectory()
        self.directory = directory
        fileSystem = DefaultFileSystem(
            config: .init(
                overrides: .init(
                    currentWorkingDirectory: directory.path.appending(component: "currentWorkingDirectory"),
                    homeDirectory: directory.path.appending(component: "home")
                )
            )
        )
        try! fileSystem.createDirectory(at: fileSystem.homeDirectory.appending(components: [".curie", "plugins"]))
        try! fileSystem.createDirectory(at: fileSystem.currentWorkingDirectory)
    }

    func resolveInteractor() -> Interactor {
        let systemContainer = DefaultContainer()
        Assembler(container: systemContainer).assemble([
            CommonAssembly(),
            CoreAssembly(),
        ])
        let testContainer = DefaultContainer(parent: systemContainer)
        testContainer.register(RestoreImageService.self) { [restoreImageService] _ in restoreImageService }
        testContainer.register(System.self) { [system] _ in system }
        testContainer.register(FileSystem.self) { [fileSystem] _ in fileSystem }
        testContainer.register(HTTPClient.self) { [httpClient] _ in httpClient }
        testContainer.register(Console.self) { [console] _ in console }
        testContainer.register(CurieCommon.RunLoop.self) { [runLoop] _ in runLoop }
        return testContainer.resolve(Interactor.self)
    }
}

extension FileManager {
    func markAsExecuable(atPath path: String) throws {
        // Get current file attributes
        let attributes = try attributesOfItem(atPath: path)

        // Extract the current file permissions
        if let filePermissions = attributes[FileAttributeKey.posixPermissions] as? NSNumber {
            // Convert current permissions to integer
            var permissions = filePermissions.intValue

            // Add execute permission for the owner (User) by using bitwise OR
            // 0o100 (octal) adds the execute permission for the owner
            permissions |= 0o100

            // Set the new permissions
            try setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
        }
    }
}
