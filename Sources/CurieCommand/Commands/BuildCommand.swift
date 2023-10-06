import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct BuildCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "build",
        abstract: "Build an image from an image restore file."
    )

    @Argument(help: "Reference \(CurieCore.Constants.referenceFormat).")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Path to .ipsw file."
    )
    var ipswPath: String

    @Option(
        name: .shortAndLong,
        help: "Disk size (default \(CurieCore.Constants.defaultDiskSize))."
    )
    var diskSize: String?

    @Option(
        name: .shortAndLong,
        help: "Path to config file."
    )
    var configPath: String?

    final class Executor: CommandExecutor {
        private let interactor: BuildInteractor
        private let console: Console

        init(interactor: BuildInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: BuildCommand) throws {
            try interactor.execute(with: .init(
                ipwsPath: command.ipswPath,
                reference: command.reference,
                diskSize: command.diskSize,
                configPath: command.configPath
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(BuildInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
