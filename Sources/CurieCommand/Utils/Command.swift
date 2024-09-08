//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
