import ArgumentParser
import CurieCommon
import Foundation
import SCInject

protocol CommandExecutor {
    associatedtype Command

    func execute(command: Command) throws
}

protocol Command: ParsableCommand {
    associatedtype Executor: CommandExecutor where Executor.Command == Self
}

extension Command {
    func run() throws {
        try resolver.resolve(Executor.self).execute(command: self)
    }
}

protocol CommandAssembly: Assembly {}

enum CommandError: Error {
    case exit(Int32)

    var exitCode: Int32 {
        switch self {
        case let .exit(exitCode):
            exitCode
        }
    }
}

extension CommandExecutor {
    func exit(_ code: Int32) -> CommandError {
        CommandError.exit(code)
    }
}
