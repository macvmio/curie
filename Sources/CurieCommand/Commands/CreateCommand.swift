import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct CreateCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "create",
        abstract: "Create a macOS VM."
    )

    @Argument(help: "Reference <repository>:<tag>.")
    var reference: String

    @Option(
        name: .shortAndLong,
        help: "Path to .ipsw file.",
        completion: .directory
    )
    var ipswPath: String?

    @Option(
        name: .shortAndLong,
        help: "Disk size (default \(CurieCore.Constants.defaultDiskSize)).",
        completion: .directory
    )
    var diskSize: String?

    @Option(
        name: .shortAndLong,
        help: "Path to config file.",
        completion: .directory
    )
    var configPath: String?

    final class Executor: CommandExecutor {
        private let interactor: CreateInteractor
        private let console: Console

        init(interactor: CreateInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: CreateCommand) throws {
            try interactor.execute(with: .init(
                source: command.source,
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
                    interactor: r.resolve(CreateInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}

private extension CreateCommand {
    var source: CreateInteractorContext.Source {
        if let ipswPath {
            return .ipsw(path: ipswPath)
        }
        return .latest
    }
}
