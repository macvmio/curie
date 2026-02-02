//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
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
import CurieCore
import Foundation
import SCInject
import TSCBasic

struct SocketJSONCommand: Command {
    static let configuration: CommandConfiguration = .init(
        commandName: "json",
        abstract: "Send complext JSON requests to the socket."
    )

    @Option(name: [.customShort("t"), .long], help: "Use unix socket at this path to interact with running VM over it.")
    var socketPath: String

    @Option(
        name: [.customShort("r"), .long],
        help: "JSON payload to send to socket, must be of type CurieSocketRequest"
    )
    var socketRequest: CurieSocketRequest

    final class Executor: CommandExecutor {
        private let interactor: SocketInteractor
        private let console: Console

        init(interactor: SocketInteractor, console: Console) {
            self.interactor = interactor
            self.console = console
        }

        func execute(command: SocketJSONCommand) throws {
            try interactor.execute(
                with: .init(
                    socketPath: command.socketPath,
                    socketRequest: command.socketRequest
                )
            )
        }
    }

    final class Assembly: CommandAssembly {
        func assemble(_ registry: Registry) {
            registry.register(Executor.self) { r in
                Executor(
                    interactor: r.resolve(SocketInteractor.self),
                    console: r.resolve(Console.self)
                )
            }
        }
    }
}

extension CurieSocketRequest: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        do {
            let decoder = JSONDecoder()
            self = try decoder.decode(CurieSocketRequest.self, from: Data(argument.utf8))
        } catch {
            return nil
        }
    }

    public static var allValueStrings: [String] {
        let examples: [CurieSocketRequest] = [
            .ping(PingPayload()),
            .terminateVm(TerminateVmPayload(waitToComplete: true, timeout: 10)),
            .makeScreenshot(MakeScreenshotPayload(savePngImageAtPath: "/path/to/output.png")),
        ]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return examples
            .compactMap { curieSocketRequest in
                guard let data = try? encoder.encode(curieSocketRequest) else { return nil }
                guard let string = String(data: data, encoding: .utf8) else { return nil }
                return "\n    \(curieSocketRequest.intentHumanReadableDescription) example JSON: \(string)"
            }
    }
}
