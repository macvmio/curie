import ArgumentParser
import CurieCommon
import CurieCRI
import Foundation
import TSCUtility

struct ServeCommand: Command {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start CRI server."
    )

    final class Executor: CommandExecutor {
        private let interactor: ServeInteractor
        private let console: Console

        init(interactor: ServeInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command _: ServeCommand) throws {
            try interactor.execute(with: .init())
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ServeInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
