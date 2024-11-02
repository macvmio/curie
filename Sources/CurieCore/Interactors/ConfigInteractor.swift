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

public struct ConfigParameters {
    public var reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

final class ConfigInteractor: AsyncInteractor {
    private let imageCache: ImageCache
    private let system: System

    init(
        imageCache: ImageCache,
        system: System
    ) {
        self.imageCache = imageCache
        self.system = system
    }

    func execute(parameters: ConfigParameters) async throws {
        let reference = try imageCache.findReference(parameters.reference)
        let bundle = try imageCache.bundle(for: reference)
        try system.execute(["open", "-t", bundle.config.pathString])
    }
}
