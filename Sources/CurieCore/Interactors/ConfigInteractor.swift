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

public struct ConfigInteractorContext {
    public var reference: String

    public init(
        reference: String
    ) {
        self.reference = reference
    }
}

public protocol ConfigInteractor {
    func execute(with context: ConfigInteractorContext) throws
}

public final class DefaultConfigInteractor: ConfigInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let system: System

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        system: System
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.system = system
    }

    public func execute(with context: ConfigInteractorContext) throws {
        let reference = try imageCache.findReference(context.reference)
        let bundle = try VMBundle(path: imageCache.path(to: reference))
        try system.execute(["open", "-t", bundle.config.pathString])
    }
}
