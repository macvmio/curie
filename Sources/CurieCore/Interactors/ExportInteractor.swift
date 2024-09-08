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

public struct ExportInteractorContext {
    public var reference: String
    public var path: String
    public var compress: Bool

    public init(reference: String, path: String, compress: Bool) {
        self.reference = reference
        self.path = path
        self.compress = compress
    }
}

public protocol ExportInteractor {
    func execute(with context: ExportInteractorContext) throws
}

public final class DefaultExportInteractor: ExportInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    public func execute(with context: ExportInteractorContext) throws {
        let reference = try imageCache.findImageReference(context.reference)

        if context.compress {
            console.text("Compressing... (might take several minutes)")
        }

        try imageCache.exportImage(
            source: reference,
            destinationPath: context.path,
            mode: context.compress ? .compress : .raw
        )

        console.text("Image has been exported")
    }
}
