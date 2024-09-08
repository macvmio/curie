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

public final class Atomic<T> {
    private var value: T
    private let lock = NSLock()

    public init(value: T) {
        self.value = value
    }

    public func load() -> T {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    public func update(_ newValue: T) {
        lock.lock(); defer { lock.unlock() }
        value = newValue
    }
}
