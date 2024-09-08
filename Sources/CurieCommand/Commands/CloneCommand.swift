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

struct CloneCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "clone",
        abstract: "Clone an image."
    )

    @Argument(help: "Source reference \(CurieCore.Constants.referenceFormat).")
    var sourceReference: String

    @Argument(help: "Target reference \(CurieCore.Constants.referenceFormat).")
    var targetReference: String

    final class Executor: CommandExecutor {
        private let interactor: CloneInteractor
        private let console: Console

        init(interactor: CloneInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CloneCommand) throws {
            try interactor.execute(with: .init(
                sourceReference: command.sourceReference,
                targetReference: command.targetReference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(CloneInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
