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

public enum Constants {
    public static let defaultDiskSize = MemorySize(bytes: 128 * 1024 * 1024 * 1024)
    public static let referenceFormat = "<repository>[:<tag>]"

    static let defaultConfig = VMConfig(
        cpuCount: 4,
        memorySize: .init(bytes: 4 * 1024 * 1024 * 1024),
        display: .init(width: 1920, height: 1080, pixelsPerInch: 144),
        network: .init(devices: [
            .init(macAddress: .synthesized, mode: .NAT),
        ]),
        sharedDirectory: .init(directories: []),
        shutdown: .init(behaviour: .stop),
        clipboard: .init(enabled: false)
    )

    static let dataRootEnvironmentVariable = "CURIE_DATA_ROOT"
}
