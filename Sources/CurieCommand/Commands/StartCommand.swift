import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct StartCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "start",
        abstract: "Start a stopped container."
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

    @Flag(name: .shortAndLong, help: "Print only CONTAINER ID.")
    var quiet: Bool = false

    final class Executor: CommandExecutor {
        private let interactor: StartInteractor
        private let console: Console

        init(interactor: StartInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: StartCommand) throws {
            console.quiet = command.quiet

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
                    interactor: r.resolve(StartInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
