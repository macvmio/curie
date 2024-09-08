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

struct InspectCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "inspect",
        abstract: "Show details of an image or a container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: InspectInteractor
        private let console: Console

        init(interactor: InspectInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: InspectCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(InspectInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
