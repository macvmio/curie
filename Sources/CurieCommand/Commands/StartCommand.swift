import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct StartCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "start",
        abstract: "Start a stopped container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Flag(help: "Do not create window.")
    var noWindow: Bool = false

    @Flag(help: "Start in recovery mode.")
    var recoveryMode: Bool = false

    @Flag(help: "Share current working directory with the guest.")
    var shareCWD: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: StartInteractor
        private let console: Console

        init(interactor: StartInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: StartCommand) throws {
            try interactor.execute(
                with: .init(
                    reference: command.reference,
                    launch: .init(
                        noWindow: command.noWindow,
                        recoveryMode: command.recoveryMode,
                        shareCurrentWorkingDirectory: command.shareCWD
                    )
                )
            )
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
