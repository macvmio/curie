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

public struct ExportParameters {
    public var reference: String
    public var path: String
    public var compress: Bool

    public init(reference: String, path: String, compress: Bool) {
        self.reference = reference
        self.path = path
        self.compress = compress
    }
}

final class ExportInteractor: AsyncInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(parameters: ExportParameters) async throws {
        let reference = try imageCache.findImageReference(parameters.reference)

        if parameters.compress {
            console.text("Compressing... (might take several minutes)")
        }

        try imageCache.exportImage(
            source: reference,
            destinationPath: parameters.path,
            mode: parameters.compress ? .compress : .raw
        )

        console.text("Image has been exported")
    }
}
