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

struct SocketSynthesizeMouseCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "synthesize-mouse",
        abstract: "Synthesizes mouse input.",
        aliases: ["sm"]
    )

    @Option(name: [.customShort("t"), .long], help: "Use unix socket at this path to interact with running VM over it.")
    var socketPath: String

    @Option(help: "Mouse button.")
    var mouseButton: MouseButton = .left

    @Option(help: "Mouse coordinate, e.g. '50,100'.")
    var mouseCoordinate: String

    @Option(help: "Some meaningful timeout for input to complete.")
    var timeout: Int = .init(SynthesizeKeyboardPayload.defaultTimeout)

    final class Executor: CommandExecutor {
        private let interactor: SocketInteractor
        private let console: Console

        init(interactor: SocketInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: SocketSynthesizeMouseCommand) throws {
            try interactor.execute(
                with: .init(
                    socketPath: command.socketPath,
                    socketRequest: .synthesizeMouse(
                        SynthesizeMousePayload(
                            mouseClicks: [
                                MouseClick(
                                    point: MouseCoordinate.from(stringValue: command.mouseCoordinate),
                                    button: command.mouseButton,
                                    clickCount: 1,
                                    modifiers: [],
                                    delayAfter: 0.1
                                ),
                            ],
                            timeout: TimeInterval(command.timeout)
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

extension MouseButton: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "left": self = .left
        case "right": self = .right
        default: return nil
        }
    }
}
