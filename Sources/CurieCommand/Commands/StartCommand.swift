import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct StartCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "start",
        abstract: "Start a container to modify the image."
    )

    @Argument(help: "Reference <repository>:<tag>.")
    var reference: String

    @Flag(help: "Do not create Window.")
    var noWindow: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: StartInteractor
        private let console: Console

        init(interactor: StartInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: StartCommand) throws {
            try interactor.execute(with: .init(
                reference: command.reference,
                noWindow: command.noWindow
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(StartInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
