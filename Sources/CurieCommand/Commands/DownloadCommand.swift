import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct DownloadCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "download",
        abstract: "Download the latest version of image restore file."
    )

    @Option(
        name: .shortAndLong,
        help: "Destination path."
    )
    var path: String

    final class Executor: CommandExecutor {
        private let interactor: DownloadInteractor
        private let console: Console

        init(interactor: DownloadInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: DownloadCommand) throws {
            try interactor.execute(with: .init(
                path: command.path
            ))
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(DownloadInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
