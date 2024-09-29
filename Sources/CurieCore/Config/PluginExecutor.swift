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

public enum Plugin: String {
    case pull
    case push
}

public protocol PluginExecutor {
    func supportsCommand(_ command: String) -> Bool
    func executePlugin(_ plugin: Plugin, parameters: [String: String]) throws
}

final class DefaultPluginExecutor: PluginExecutor {
    private let system: System
    private let fileSystem: CurieCommon.FileSystem
    private let console: Console

    init(
        system: System,
        fileSystem: CurieCommon.FileSystem,
        console: Console
    ) {
        self.system = system
        self.fileSystem = fileSystem
        self.console = console
    }

    func supportsCommand(_ command: String) -> Bool {
        let pluginsDirectory = pluginsDirectory()
        guard let list = try? fileSystem.list(at: pluginsDirectory) else {
            return false
        }
        return list
            .compactMap {
                switch $0 {
                case let .file(file):
                    file.path.basename
                default:
                    nil
                }
            }
            .contains { $0 == command }
    }

    func executePlugin(_ plugin: Plugin, parameters: [String: String]) throws {
        let executablePath = pluginsDirectory().appending(component: plugin.rawValue)
        guard fileSystem.exists(at: executablePath) else {
            console.error("Plugin does not exist at '\(executablePath)'")
            return
        }
        guard fileSystem.isFile(at: executablePath) else {
            console.error("Plugin at '\(executablePath)' is not a file")
            return
        }
        guard fileSystem.isExecutable(at: executablePath) else {
            console.error("Plugin at '\(executablePath)' is not executable")
            return
        }
        let commandParameters = parameters
            .sorted(by: { $0.key < $1.key })
            .flatMap { ["--\($0.key)", $0.value] }
        let command = [executablePath.pathString] + commandParameters

        try system.execute(command)
    }

    // MARK: - Private

    // TODO: Extract and share with ImageCache
    private func pluginsDirectory() -> AbsolutePath {
        if let overrideDataRootString = system.environmentVariable(name: Constants.dataRootEnvironmentVariable) {
            return fileSystem.absolutePath(from: overrideDataRootString)
        }
        return fileSystem.homeDirectory
            .appending(components: [".curie", "plugins"])
    }
}
