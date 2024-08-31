import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct RmCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "rm",
        abstract: "Remove a container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    final class Executor: CommandExecutor {
        private let interactor: RmInteractor
        private let console: Console

        init(interactor: RmInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RmCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(RmInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
