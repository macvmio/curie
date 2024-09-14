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

struct RunCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "run",
        abstract: "Start an ephemeral container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Flag(name: .shortAndLong, help: "Do not create window.")
    var noWindow: Bool = false

    @Flag(name: .shortAndLong, help: "Start in recovery mode.")
    var recoveryMode: Bool = false

    @Flag(name: .shortAndLong, help: "Share current working directory with the guest.")
    var shareCWD: Bool = false

    @Flag(name: .shortAndLong, help: "Use main screen resolution.")
    var mainScreenResolution: Bool = false

    @Flag(name: .shortAndLong, help: "Print only CONTAINER ID.")
    var quiet: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: Interactor
        private let console: Console

        init(
            interactor: Interactor,
            console: Console
        ) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RunCommand) throws {
            console.quiet = command.quiet

            try interactor.execute(.run(.init(
                reference: command.reference,
                launch: .init(
                    noWindow: command.noWindow,
                    mainScreenResolution: command.mainScreenResolution,
                    recoveryMode: command.recoveryMode,
                    shareCurrentWorkingDirectory: command.shareCWD,
                    pauseOnExit: false
                )
            )))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(Interactor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
