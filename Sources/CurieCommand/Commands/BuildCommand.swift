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

import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct BuildCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "build",
        abstract: "Build an image from an image restore file."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Path to .ipsw file."
    )
    var ipswPath: String

    @Option(
        name: .shortAndLong,
        help: "Disk size (default \(CurieCore.Constants.defaultDiskSize))."
    )
    var diskSize: String?

    @Option(
        name: .shortAndLong,
        help: "Path to config file."
    )
    var configPath: String?

    final class Executor: CommandExecutor {
        private let interactor: Interactor

        init(interactor: Interactor) {
            self.interactor = interactor
        }

        func execute(command: BuildCommand) throws {
            try interactor.execute(.build(.init(
                ipswPath: command.ipswPath,
                reference: command.reference,
                diskSize: command.diskSize,
                configPath: command.configPath
            )))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(Interactor.self)
                )
            }
        }
    }
}
