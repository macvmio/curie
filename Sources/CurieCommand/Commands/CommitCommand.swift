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

struct CommitCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "commit",
        abstract: "Create a new image from a container's changes."
    )

    @Argument(help: "Container reference \(CurieCore.Constants.referenceFormat).")
    var containerReference: String

    @Argument(help: "Image reference \(CurieCore.Constants.referenceFormat).")
    var imageReference: String?

    final class Executor: CommandExecutor {
        private let interactor: Interactor

        init(interactor: Interactor) {
            self.interactor = interactor
        }

        func execute(command: CommitCommand) throws {
            try interactor.execute(.commit(.init(
                containerReference: command.containerReference,
                imageReference: command.imageReference
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
