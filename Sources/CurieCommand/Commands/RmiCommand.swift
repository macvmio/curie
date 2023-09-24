import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct RmiCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "rmi",
        abstract: "Remove an image."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    final class Executor: CommandExecutor {
        private let interactor: RmiInteractor
        private let console: Console

        init(interactor: RmiInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RmiCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(RmiInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
