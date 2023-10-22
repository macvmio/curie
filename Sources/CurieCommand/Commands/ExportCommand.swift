import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct ExportCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "export",
        abstract: "Export image."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Destination path."
    )
    var path: String

    @Flag(name: .shortAndLong, help: "Compress exported image.")
    var compress: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: ExportInteractor
        private let console: Console

        init(interactor: ExportInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ExportCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                path: command.path,
                compress: command.compress
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ExportInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
