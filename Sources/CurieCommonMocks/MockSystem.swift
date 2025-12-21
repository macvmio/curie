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

import CurieCommon
import Foundation

public final class MockSystem: System {
    public enum Call: Equatable {
        case execute([String])
        case executeWithOutput([String])
    }

    public private(set) var calls: [Call] = []
    public var mockExecuteOutput: String?
    public var mockEnvironmentVariables: [String: String] = [:]

    public init() {}

    public func makeSIGINTSourceSignal(
        signalHandler _: @escaping () -> ()
    ) -> DispatchSourceSignal {
        fatalError("Not implemented yet")
    }

    public func makeSIGTERMSourceSignal(
        signalHandler _: @escaping () -> ()
    ) -> DispatchSourceSignal {
        fatalError("Not implemented yet")
    }

    public func keepAlive(
        signalHandler _: @escaping () -> ()
    ) {
        fatalError("Not implemented yet")
    }

    public func keepAliveWithSIGINTEventHandler(
        cancellable _: CurieCommon.Cancellable,
        signalHandler _: @escaping () -> ()
    ) {
        fatalError("Not implemented yet")
    }

    public func execute(_ arguments: [String]) throws {
        calls.append(.execute(arguments))
    }

    public func execute(_ arguments: [String], output: CurieCommon.OutputType) throws {
        calls.append(.executeWithOutput(arguments))
        switch output {
        case .stdout:
            break
        case .muted:
            break
        case let .custom(output):
            if let mockExecuteOutput {
                output.write(mockExecuteOutput)
            }
        }
    }

    public func environmentVariable(name: String) -> String? {
        mockEnvironmentVariables[name]
    }
}
