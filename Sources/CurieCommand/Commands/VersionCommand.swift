import ArgumentParser
import CurieCommon
import Foundation
import SCInject
import TSCUtility

struct VersionCommand: Command {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show version."
    )

    final class Executor: CommandExecutor {
        private let console: Console

        init(console: Console) {
            self.console = console
        }

        func execute(command _: VersionCommand) throws {
            console.text(Constants.version.description)
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(console: r.resolve(Console.self))
            }
        }
    }
}
