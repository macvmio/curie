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

struct ARPItem: Equatable, Codable {
    let ip: String
    let macAddress: String
}

protocol ARPClient {
    func executeARPQuery() throws -> [ARPItem]
}

final class DefaultARPClient: ARPClient {
    private let system: System

    init(system: System) {
        self.system = system
    }

    func executeARPQuery() throws -> [ARPItem] {
        let captureOutput = CaptureOutput()
        try system.execute(["/usr/sbin/arp", "-an"], output: .custom(captureOutput))

        let tokens = captureOutput.outputString
            .split(separator: "\n")
            .map { $0.split(separator: " ") }

        let items: [ARPItem] = tokens
            .filter { $0.count >= 4 }
            .compactMap {
                guard let macAddress = parseMAC(raw: $0[3]) else {
                    return nil
                }
                return ARPItem(
                    ip: parseIP(raw: $0[1]),
                    macAddress: macAddress
                )
            }

        return items
    }

    private func parseIP(raw: Substring.SubSequence) -> String {
        String(raw.dropFirst().dropLast())
    }

    private func parseMAC(raw: Substring.SubSequence) -> String? {
        let components = raw.split(separator: ":")
        guard components.count == 6 else {
            return nil
        }
        let normalizedComponents = components.map {
            if $0.count == 1 {
                "0\($0.lowercased())"
            } else {
                $0.lowercased()
            }
        }
        return normalizedComponents.joined(separator: ":")
    }
}
