//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
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

struct SocketSynthesizeKeyboardCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "synthesize-keyboard",
        abstract: "Synthesizes keyboard input to type specified text.",
        aliases: ["sk"]
    )

    @Option(name: [.customShort("t"), .long], help: "Use unix socket at this path to interact with running VM over it.")
    var socketPath: String

    @Option(help: "Text input to synthesize; to synthesize complex input use `socket json` command.")
    var input: String

    final class Executor: CommandExecutor {
        private let interactor: SocketInteractor
        private let console: Console

        init(interactor: SocketInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: SocketSynthesizeKeyboardCommand) throws {
            try interactor.execute(
                with: .init(
                    socketPath: command.socketPath,
                    socketRequest: .synthesizeKeyboard(
                        SynthesizeKeyboardPayload(
                            input: KeyboardInput(
                                content: .text(command.input)
                            )
                        )
                    )
                )
            )
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(SocketInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
