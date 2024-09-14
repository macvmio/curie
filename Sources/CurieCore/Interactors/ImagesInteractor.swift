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

public struct ImagesParameters {
    public let format: OutputFormat

    public init(format: OutputFormat) {
        self.format = format
    }
}

final class ImagesInteractor: AsyncInteractor {
    private let imageCache: ImageCache
    private let wallClock: WallClock
    private let console: Console

    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(
        imageCache: ImageCache,
        wallClock: WallClock,
        console: Console
    ) {
        self.imageCache = imageCache
        self.wallClock = wallClock
        self.console = console
    }

    func execute(parameters: ImagesParameters) async throws {
        let items = try imageCache.listImages()
        let images = items.sorted { $0.createAt > $1.createAt }

        let rendered = TableRenderer()
        let content = TableRenderer.Content(
            headers: [
                "repository",
                "tag",
                "image id",
                "created",
                "size",
            ],
            values: images.map { [
                $0.reference.descriptor.repository,
                $0.reference.descriptor.tag ?? "<none>",
                $0.reference.id.description,
                dateFormatter.localizedString(for: $0.createAt, relativeTo: wallClock.now()),
                $0.size.description,
            ] }
        )
        let config = TableRenderer.Config(format: parameters.format.rendererFormat())
        let text = rendered.render(content: content, config: config)

        console.text(text)
    }
}
