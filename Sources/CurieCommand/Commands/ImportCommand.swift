import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct ImportCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "import",
        abstract: "Import image."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Path to image file or directory."
    )
    var path: String

    final class Executor: CommandExecutor {
        private let interactor: ImportInteractor
        private let console: Console

        init(interactor: ImportInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ImportCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                path: command.path
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ImportInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
