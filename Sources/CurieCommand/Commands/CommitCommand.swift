import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct CommitCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "commit",
        abstract: "Create a new image from a container's changes."
    )

    @Argument(help: "Container reference \(CurieCore.Constants.referenceFormat).")
    var containerReference: String

    @Argument(help: "Image reference \(CurieCore.Constants.referenceFormat).")
    var imageReference: String?

    final class Executor: CommandExecutor {
        private let interactor: CommitInteractor
        private let console: Console

        init(interactor: CommitInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CommitCommand) throws {
            try interactor.execute(with: .init(
                containerReference: command.containerReference,
                imageReference: command.imageReference
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(CommitInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
