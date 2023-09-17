import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct ListCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "ls",
        abstract: "List images."
    )

    @Flag(
        name: .shortAndLong,
        help: "List containers."
    )
    var containers: Bool = false

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: ListInteractor
        private let console: Console

        init(interactor: ListInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ListCommand) throws {
            try interactor.execute(with: .init(
                listContainers: command.containers,
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ListInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
