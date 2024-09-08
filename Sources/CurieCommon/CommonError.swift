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

import Foundation

public struct SubprocessCoreError: Error {
    public let exitCode: Int32
}

public enum CoreError: LocalizedError, Equatable {
    case generic(String)

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String
    ) throws -> T {
        try rethrow(closure(), .generic(message()))
    }

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ coreError: @autoclosure () -> CoreError
    ) throws -> T {
        do {
            return try closure()
        } catch {
            throw coreError()
        }
    }

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ coreError: (String) -> CoreError
    ) throws -> T {
        do {
            return try closure()
        } catch let error as LocalizedError {
            throw coreError(error.localizedDescription)
        } catch {
            throw coreError(String(describing: error))
        }
    }

    static func rethrowCommand<T>(
        _ closure: () throws -> T,
        command: [String],
        message: String
    ) throws -> T {
        do {
            return try closure()
        } catch is SubprocessCoreError {
            throw CoreError.generic("""
            \(message)

            Failed command:
            > \(command.command())

            """)
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .generic(message):
            message
        }
    }
}
