import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct ConfigCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "config",
        abstract: "Configure image or container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    final class Executor: CommandExecutor {
        private let interactor: ConfigInteractor
        private let console: Console

        init(interactor: ConfigInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ConfigCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ConfigInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
