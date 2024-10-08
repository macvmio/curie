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

struct VMMetadata: Equatable, Codable {
    struct NetworkDevice: Equatable, Codable {
        let MACAddress: String
    }

    struct Network: Equatable, Codable {
        var devices: [Int: NetworkDevice] = [:]
    }

    var id: ImageID
    var name: String?
    var createdAt: Date
    var network: Network?
}

extension VMMetadata: CustomStringConvertible {
    public var description: String {
        """
        Metadata:
          id: \(id.description)
          name: \(name ?? "<none>")
          createdAt: \(dateFormatter.string(from: createdAt))
          network:
            devices:
        \(network?.devices.description ?? "")
        """
    }

    private var dateFormatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
}

extension [Int: VMMetadata.NetworkDevice] {
    var description: String {
        let prefix = "      "
        guard !isEmpty else {
            return "\(prefix)N/A"
        }
        return sorted { $0.key < $1.key }.map { index, value in
            """
            \(prefix)index: \(index)
            \(prefix)macAddress: \(value.MACAddress)
            """
        }.joined(separator: "\n\n")
    }
}
