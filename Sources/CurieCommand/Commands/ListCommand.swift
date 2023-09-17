import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import TSCBasic

struct ListCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "ls",
        abstract: "List images."
    )

    @Flag(
        name: .shortAndLong,
        help: "List containers."
    )
    var containers: Bool = false

    @Option(
        name: .shortAndLong,
        help: "Format \"text\" or \"json\" (\"text\" by default).",
        completion: .default
    )
    var format: String = "text"

    final class Executor: CommandExecutor {
        private let interactor: ListInteractor
        private let console: Console

        init(interactor: ListInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: ListCommand) throws {
            try interactor.execute(with: .init(
                listContainers: command.containers,
                format: parseFormat(command)
            ))
        }

        private func parseFormat(_ command: ListCommand) throws -> ListInteractorContext.Format {
            switch command.format {
            case "text":
                return .text
            case "json":
                return .json
            default:
                throw CoreError
                    .generic("Unexpected format option (\"\(command._format)\"), please use \"text\" or \"json\"")
            }
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(ListInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}
