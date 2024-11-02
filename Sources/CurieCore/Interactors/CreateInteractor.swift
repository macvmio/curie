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

import Combine
import CurieCommon
import Foundation

public struct CreateParameters {
    public var reference: String
    public var name: String?

    public init(
        reference: String,
        name: String?
    ) {
        self.reference = reference
        self.name = name
    }
}

final class CreateInteractor: AsyncInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let console: Console

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        console: Console
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.console = console
    }

    func execute(parameters: CreateParameters) async throws {
        let sourceReference = try imageCache.findImageReference(parameters.reference)
        let targetReference = try imageCache.cloneImage(source: sourceReference, target: .newReference)

        let bundle = try imageCache.bundle(for: targetReference)
        try bundleParser.updateMetadata(bundle: bundle) { metadata in
            metadata.name = parameters.name
        }

        console.text(targetReference.id.description)
    }
}
