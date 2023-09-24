import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct PsCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "ps",
        abstract: "List containers."
    )

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: PsInteractor
        private let console: Console

        init(interactor: PsInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: PsCommand) throws {
            try interactor.execute(with: .init(
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(PsInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
