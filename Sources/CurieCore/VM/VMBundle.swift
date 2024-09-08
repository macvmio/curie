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
import TSCBasic

public struct VMBundle {
    public let path: AbsolutePath

    static let fileExtension = "curie"

    init(path: AbsolutePath) {
        self.path = path
    }

    public var name: String {
        path.basename
    }

    public var machineIdentifier: AbsolutePath {
        path("machine-identifier.bin")
    }

    public var auxilaryStorage: AbsolutePath {
        path("auxilary-storage.bin")
    }

    public var hardwareModel: AbsolutePath {
        path("hardware-model.bin")
    }

    public var diskImage: AbsolutePath {
        path("disk.img")
    }

    public var config: AbsolutePath {
        path("config.json")
    }

    public var metadata: AbsolutePath {
        path("metadata.json")
    }

    public var container: AbsolutePath {
        path("container.json")
    }

    public var machineState: AbsolutePath {
        path("machine-state.bin")
    }

    // MARK: - Private

    private func path(_ filename: String) -> AbsolutePath {
        path.appending(component: filename)
    }
}
