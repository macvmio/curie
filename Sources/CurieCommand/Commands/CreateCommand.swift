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

struct CreateCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "create",
        abstract: "Create a new container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Assign a name to the container.",
        completion: .default
    )
    var name: String?

    final class Executor: CommandExecutor {
        private let interactor: CreateInteractor
        private let console: Console

        init(interactor: CreateInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CreateCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                name: command.name
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(CreateInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
