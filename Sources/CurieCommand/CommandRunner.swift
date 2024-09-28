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

public final class CommandRunner {
    public init() {}

    public func run(with arguments: [String]) -> Int32 {
        MainCommand.run(with: arguments)
    }
}

private struct MainCommand: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "curie",
        subcommands: MainCommand.allSubcommands
    )

    func run() throws {
        _ = MainCommand.run(with: ["--help"])
    }

    static func run(with arguments: [String]? = nil) -> Int32 {
        Assembler(container: DefaultContainer())
            .assemble([CommonAssembly()])
            .assemble([Assembly()])
            .resolver()
            .resolve(Executor.self)
            .execute(with: arguments ?? [])
    }

    final class Executor {
        private let console: Console
        private let errorHandler: ErrorHandler

        init(console: Console, errorHandler: ErrorHandler) {
            self.console = console
            self.errorHandler = errorHandler
        }

        func printHelp() {
            console.text(helpMessage())
        }

        func execute(with arguments: [String]) -> Int32 {
            do {
                var command = try parseAsRoot(arguments)
                try command.run()
                return 0
            } catch {
                return errorHandler.handle(error: error)
            }
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    console: r.resolve(Console.self),
                    errorHandler: r.resolve(ErrorHandler.self)
                )
            }
            registry.register(ErrorHandler.self) { r in
                ErrorHandler(console: r.resolve(Console.self))
            }
        }
    }
}

private final class ErrorHandler {
    private let console: Console

    init(console: Console) {
        self.console = console
    }

    func handle(error: Error) -> Int32 {
        if let error = error as? CoreError {
            return handleCoreError(error)
        }
        if let error = error as? CommandError {
            return handleCommandError(error)
        }
        return handleError(error)
    }

    // MARK: - Private

    private func handleCoreError(_ error: CoreError) -> Int32 {
        console.error(error.localizedDescription)
        return error.exitCode
    }

    private func handleCommandError(_ error: CommandError) -> Int32 {
        error.exitCode
    }

    private func handleError(_ error: Error) -> Int32 {
        console.text(MainCommand.fullMessage(for: error))
        return MainCommand.exitCode(for: error).rawValue
    }
}
