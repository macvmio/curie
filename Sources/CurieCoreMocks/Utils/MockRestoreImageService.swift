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
import CurieCore
import Foundation
import Virtualization

public final class MockRestoreImageService: RestoreImageService {
    private let _mockLatestSupported = Atomic<[CurieCore.RestoreImage]>(value: [])

    public var mockLatestSupported: [CurieCore.RestoreImage] {
        get { _mockLatestSupported.load() }
        set { _mockLatestSupported.update(newValue) }
    }

    public init() {}

    public func latestSupported() async throws -> CurieCore.RestoreImage {
        guard let latestSupported = _mockLatestSupported.withLock({ $0.popLast() }) else {
            fatalError("Missing mock latest supported")
        }
        return latestSupported
    }
}
