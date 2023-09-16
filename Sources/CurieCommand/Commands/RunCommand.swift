import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct RunCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "run",
        abstract: "Run a macOS VM."
    )

    @Argument(help: "Reference <repository>:<tag>.")
    var reference: String

    @Flag(help: "Do not create Window.")
    var noWindow: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: RunInteractor
        private let console: Console

        init(interactor: RunInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RunCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                noWindow: command.noWindow
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(RunInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
