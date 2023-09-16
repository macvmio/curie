import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct RemoveCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "rm",
        abstract: "Remove image."
    )

    @Argument(help: "Reference <repository>:<tag>.")
    var reference: String

    final class Executor: CommandExecutor {
        private let interactor: RemoveInteractor
        private let console: Console

        init(interactor: RemoveInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RemoveCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(RemoveInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
