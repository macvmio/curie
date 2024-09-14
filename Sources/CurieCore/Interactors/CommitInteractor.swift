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

public struct CommitParameters {
    public var containerReference: String
    public var imageReference: String?

    public init(containerReference: String, imageReference: String?) {
        self.containerReference = containerReference
        self.imageReference = imageReference
    }
}

final class CommitInteractor: AsyncInteractor {
    private let configurator: VMConfigurator
    private let imageCache: ImageCache
    private let console: Console

    init(
        configurator: VMConfigurator,
        imageCache: ImageCache,
        console: Console
    ) {
        self.configurator = configurator
        self.imageCache = imageCache
        self.console = console
    }

    func execute(parameters: CommitParameters) async throws {
        let sourceReference = try imageCache.findContainerReference(parameters.containerReference)
        let targetReference = try parameters.imageReference.map { try ImageReference(
            id: sourceReference.id,
            descriptor: .init(reference: $0),
            type: .image
        ) } ?? sourceReference.asImageReference()

        try imageCache.moveImage(source: sourceReference, target: targetReference)

        console.text("Image \(targetReference.id.description) has been saved")
    }
}

private extension ImageReference {
    func asImageReference() -> ImageReference {
        ImageReference(
            id: id,
            descriptor: .init(repository: String(descriptor.repository.dropFirst(14)), tag: descriptor.tag),
            type: .image
        )
    }
}
