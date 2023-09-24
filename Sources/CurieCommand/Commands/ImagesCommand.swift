import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct ImagesCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "images",
        abstract: "List images."
    )

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: ImagesInteractor
        private let console: Console

        init(interactor: ImagesInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ImagesCommand) throws {
            try interactor.execute(with: .init(
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ImagesInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
