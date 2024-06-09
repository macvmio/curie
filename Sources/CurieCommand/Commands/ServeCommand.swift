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

    @Option(
        name: .long,
        help: "Use host.",
        completion: .default
    )
    var host: String = "localhost"

    @Option(
        name: .long,
        help: "Use port.",
        completion: .default
    )
    var port: Int = 0

    final class Executor: CommandExecutor {
        private let interactor: ServeInteractor
        private let console: Console

        init(interactor: ServeInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ServeCommand) throws {
            try interactor.execute(
                with: .init(
                    host: command.host,
                    port: command.port
                )
            )
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
