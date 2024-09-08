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

enum ImageType {
    case container
    case image
}

struct ImageDescriptor: Equatable {
    let repository: String
    let tag: String?

    init(repository: String, tag: String?) {
        self.repository = repository
        self.tag = tag
    }

    init(reference: String) throws {
        if let index = reference.lastIndex(of: ":") {
            let repository = String(reference.prefix(upTo: index))
            let tag = String(reference.suffix(from: reference.index(after: index)))
            self = .init(repository: repository, tag: !tag.isEmpty ? tag : nil)
        } else {
            self = .init(repository: reference, tag: nil)
        }
    }
}

struct ImageReference: Equatable {
    let id: ImageID
    let descriptor: ImageDescriptor
    let type: ImageType
}
