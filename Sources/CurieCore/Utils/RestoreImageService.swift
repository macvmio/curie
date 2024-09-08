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

import Foundation
import Virtualization

public struct RestoreImage: Equatable {
    var url: URL
    var isSupported: Bool
    var buildVersion: String
    var operatingSystemVersion: String

    public init(url: URL, isSupported: Bool, buildVersion: String, operatingSystemVersion: String) {
        self.url = url
        self.isSupported = isSupported
        self.buildVersion = buildVersion
        self.operatingSystemVersion = operatingSystemVersion
    }
}

public protocol RestoreImageService {
    func latestSupported() async throws -> RestoreImage
}

final class DefaultRestoreImageService: RestoreImageService {
    func latestSupported() async throws -> RestoreImage {
        try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.fetchLatestSupported { result in
                switch result {
                case let .success(restoreImage):
                    continuation.resume(returning: .init(
                        url: restoreImage.url,
                        isSupported: restoreImage.isSupported,
                        buildVersion: restoreImage.buildVersion,
                        operatingSystemVersion: restoreImage.operatingSystemVersion.description
                    ))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension OperatingSystemVersion {
    var description: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}
