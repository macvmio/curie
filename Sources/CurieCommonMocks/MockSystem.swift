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
    public enum Call: Equatable, Sendable {
        case execute([String])
        case executeWithOutput([String])
    }

    private let _state = Atomic<State>(value: State())

    private struct State: Sendable {
        var calls: [Call] = []
        var mockExecuteOutput: String?
        var mockEnvironmentVariables: [String: String] = [:]
    }

    public var calls: [Call] {
        _state.withLock { $0.calls }
    }

    public var mockExecuteOutput: String? {
        get { _state.withLock { $0.mockExecuteOutput } }
        set { _state.withLock { $0.mockExecuteOutput = newValue } }
    }

    public var mockEnvironmentVariables: [String: String] {
        get { _state.withLock { $0.mockEnvironmentVariables } }
        set { _state.withLock { $0.mockEnvironmentVariables = newValue } }
    }

    public init() {}

    public func makeSIGINTSourceSignal(
        signalHandler _: @escaping () -> Void
    ) -> DispatchSourceSignal {
        fatalError("Not implemented yet")
    }

    public func makeSIGTERMSourceSignal(
        signalHandler _: @escaping () -> Void
    ) -> DispatchSourceSignal {
        fatalError("Not implemented yet")
    }

    public func keepAlive(
        signalHandler _: @escaping () -> Void
    ) {
        fatalError("Not implemented yet")
    }

    public func keepAliveWithSIGINTEventHandler(
        cancellable _: CurieCommon.Cancellable,
        signalHandler _: @escaping () -> Void
    ) {
        fatalError("Not implemented yet")
    }

    public func execute(_ arguments: [String]) throws {
        _state.withLock { $0.calls.append(.execute(arguments)) }
    }

    public func execute(_ arguments: [String], output: CurieCommon.OutputType) throws {
        let mockOutput = _state.withLock {
            $0.calls.append(.executeWithOutput(arguments))
            return $0.mockExecuteOutput
        }
        switch output {
        case .stdout:
            break
        case .muted:
            break
        case let .custom(output):
            if let mockOutput {
                output.write(mockOutput)
            }
        }
    }

    public func environmentVariable(name: String) -> String? {
        _state.withLock { $0.mockEnvironmentVariables[name] }
    }
}
