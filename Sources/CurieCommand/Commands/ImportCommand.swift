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

struct ImportCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "import",
        abstract: "Import image."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Path to image file or directory."
    )
    var path: String

    final class Executor: CommandExecutor {
        private let interactor: ImportInteractor
        private let console: Console

        init(interactor: ImportInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ImportCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                path: command.path
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ImportInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
