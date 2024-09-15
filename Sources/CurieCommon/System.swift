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

import Dispatch
import Foundation
import TSCBasic

public enum OutputType {
    case `default`
    case muted
    case custom(Output)

    var output: Output {
        switch self {
        case .default:
            StandardOutput.shared
        case .muted:
            ForwardOutput(stdout: nil, stderr: nil)
        case let .custom(output):
            output
        }
    }
}

public protocol System {
    func execute(_ arguments: [String]) throws

    func execute(_ arguments: [String], output: OutputType) throws

    func environmentVariable(name: String) -> String?
}

final class DefaultSystem: System {
    private let environment = ProcessInfo.processInfo.environment

    func execute(_ arguments: [String]) throws {
        try execute(arguments, output: .default)
    }

    func execute(_ arguments: [String], output: OutputType) throws {
        let result: ProcessResult
        do {
            let process = Process(
                arguments: arguments,
                outputRedirection: output.outputRedirection(),
                startNewProcessGroup: false
            )
            try process.launch()
            result = try process.waitUntilExit()
        } catch {
            throw CoreError.generic(error.localizedDescription)
        }
        try result.throwIfErrored()
    }

    func environmentVariable(name: String) -> String? {
        ProcessInfo.processInfo.environment[name]
    }
}

private extension OutputType {
    func outputRedirection() -> TSCBasic.Process.OutputRedirection {
        switch self {
        case .default:
            .none
        default:
            .stream { [output] bytes in output.write(bytes, to: .stdout) }
                stderr: { [output] bytes in output.write(bytes, to: .stderr)
                }
        }
    }
}

private extension ProcessResult {
    func throwIfErrored() throws {
        switch exitStatus {
        case let .signalled(signal: code):
            throw SubprocessCoreError(exitCode: code)
        case let .terminated(code: code):
            guard code == 0 else {
                throw SubprocessCoreError(exitCode: code)
            }
        }
    }
}
