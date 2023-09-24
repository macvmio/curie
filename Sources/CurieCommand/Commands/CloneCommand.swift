import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct CloneCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "clone",
        abstract: "Clone an image."
    )

    @Argument(help: "Source reference \(CurieCore.Constants.referenceFormat).")
    var sourceReference: String

    @Argument(help: "Target reference \(CurieCore.Constants.referenceFormat).")
    var targetReference: String

    final class Executor: CommandExecutor {
        private let interactor: CloneInteractor
        private let console: Console

        init(interactor: CloneInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CloneCommand) throws {
            try interactor.execute(with: .init(
                sourceReference: command.sourceReference,
                targetReference: command.targetReference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(CloneInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
