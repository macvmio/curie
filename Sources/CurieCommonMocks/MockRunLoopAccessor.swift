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

public final class MockRunLoopAccessor: RunLoopAccessor {
    public enum Call: Equatable {
        case terminate
        case error(CurieCommon.CoreError)
    }

    public private(set) var calls: [Call] = []

    public init() {}

    public func terminate() {
        calls.append(.terminate)
    }

    public func error(_ error: CurieCommon.CoreError) {
        calls.append(.error(error))
    }
}
