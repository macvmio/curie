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

public struct InspectParameters {
    public var reference: String
    public let format: OutputFormat

    public init(
        reference: String,
        format: OutputFormat
    ) {
        self.reference = reference
        self.format = format
    }
}

final class InspectInteractor: AsyncInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let aprClient: ARPClient
    private let console: Console

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        aprClient: ARPClient,
        console: Console
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.aprClient = aprClient
        self.console = console
    }

    func execute(parameters: InspectParameters) async throws {
        let reference = try imageCache.findReference(parameters.reference)
        let bundle = try imageCache.bundle(for: reference)
        let info = try bundleParser.readInfo(from: bundle)
        let arpItems = try aprClient.executeARPQuery()
        let macAddresses = Set(info.metadata.network.flatMap { $0.devices.map(\.value.MACAddress) } ?? [])
        let filteredArpaRows = arpItems.filter { macAddresses.contains($0.macAddress) }

        let item = Item(info: info, arp: filteredArpaRows)

        switch parameters.format {
        case .text:
            renderText(item)
        case .json:
            try renderJson(item)
        }
    }

    // MARK: - Private

    private func renderText(_ item: Item) {
        console.text(item.description)
    }

    private func renderJson(_ item: Item) throws {
        let data = try jsonEncoder.encode(item)
        guard let string = String(data: data, encoding: .utf8) else {
            return
        }
        console.text(string)
    }
}

private struct Item: Codable {
    var info: VMInfo
    var arp: [ARPItem]
}

extension Item: CustomStringConvertible {
    var description: String {
        """
        \(info.description)\(arp.description)
        """
    }
}

extension [ARPItem] {
    var description: String {
        guard !isEmpty else {
            return ""
        }
        return """

        ARP:
        \(
            enumerated()
                .map { $1.description }
                .joined(separator: "\n")
        )

        """
    }
}

extension ARPItem: CustomStringConvertible {
    var description: String {
        """
          macAddress: \(macAddress)
          ip: \(ip)
        """
    }
}
