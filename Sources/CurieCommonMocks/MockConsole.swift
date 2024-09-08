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

public final class MockOutput: Output {
    public enum Call: Equatable {
        case write(string: String, stream: CurieCommon.OutputStream)
    }

    public private(set) var calls: [Call] = []

    public func write(_ string: String, to stream: CurieCommon.OutputStream) {
        calls.append(.write(string: string, stream: stream))
    }

    public var redirected: Bool = false
}

public final class MockConsole: Console {
    public enum Call: Equatable {
        // swiftlint:disable:next duplicate_enum_cases
        case text(String)

        // swiftlint:disable:next duplicate_enum_cases
        case text(String, Bool)
        case error(String)
        case clear

        // swiftlint:disable:next duplicate_enum_cases
        case progress(String, Double)

        // swiftlint:disable:next duplicate_enum_cases
        case progress(String, Double, String?)
    }

    public private(set) var calls: [Call] = []

    public var output: any CurieCommon.Output = MockOutput()
    public var quiet: Bool = false

    public init() {}

    public func text(_ message: String) {
        calls.append(.text(message))
    }

    public func text(_ message: String, always: Bool) {
        calls.append(.text(message, always))
    }

    public func error(_ message: String) {
        calls.append(.error(message))
    }

    public func clear() {
        calls.append(.clear)
    }

    public func progress(prompt: String, progress: Double) {
        calls.append(.progress(prompt, progress))
    }

    public func progress(prompt: String, progress: Double, suffix: String?) {
        calls.append(.progress(prompt, progress, suffix))
    }
}
