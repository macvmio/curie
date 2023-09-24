import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct InspectCommand: Command, HasFormatOption {
    static let configuration: CommandConfiguration = .init(
        commandName: "inspect",
        abstract: "Show details of an image or a container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: Options.format.help,
        completion: .default
    )
    var format: String = Options.format.defaultValue

    final class Executor: CommandExecutor {
        private let interactor: InspectInteractor
        private let console: Console

        init(interactor: InspectInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: InspectCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                format: command.parseFormatOption()
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(InspectInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
