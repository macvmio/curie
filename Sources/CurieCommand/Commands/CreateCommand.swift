import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct CreateCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "create",
        abstract: "Create a new container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Assign a name to the container.",
        completion: .default
    )
    var name: String?

    final class Executor: CommandExecutor {
        private let interactor: CreateInteractor
        private let console: Console

        init(interactor: CreateInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CreateCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                name: command.name
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(CreateInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
