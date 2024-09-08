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

struct ImagesCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "images",
        abstract: "List images."
    )

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: ImagesInteractor
        private let console: Console

        init(interactor: ImagesInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ImagesCommand) throws {
            try interactor.execute(with: .init(
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ImagesInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
