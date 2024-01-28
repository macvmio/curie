import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct RunCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "run",
        abstract: "Start an ephemeral container."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Flag(name: .shortAndLong, help: "Do not create window.")
    var noWindow: Bool = false

    @Flag(name: .shortAndLong, help: "Pause on exit (requires macOS 14.0+).")
    var pauseOnExit: Bool = false

    @Flag(name: .shortAndLong, help: "Start in recovery mode.")
    var recoveryMode: Bool = false

    @Flag(name: .shortAndLong, help: "Share current working directory with the guest.")
    var shareCWD: Bool = false

    @Flag(name: .shortAndLong, help: "Use main screen resolution.")
    var mainScreenResolution: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: RunInteractor
        private let console: Console

        init(interactor: RunInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: RunCommand) throws {
            try interactor.execute(
                with: .init(
                    reference: command.reference,
                    launch: .init(
                        noWindow: command.noWindow,
                        mainScreenResolution: command.mainScreenResolution,
                        recoveryMode: command.recoveryMode,
                        shareCurrentWorkingDirectory: command.shareCWD,
                        pauseOnExit: command.pauseOnExit
                    )
                )
            )
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(RunInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
