import CurieCommon
import Foundation

public struct InspectInteractorContext {
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

public protocol InspectInteractor {
    func execute(with context: InspectInteractorContext) throws
}

final class DefaultInspectInteractor: InspectInteractor {
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

    func execute(with context: InspectInteractorContext) throws {
        let reference = try imageCache.findReference(context.reference)
        let bundle = VMBundle(path: imageCache.path(to: reference))
        let info = try bundleParser.readInfo(from: bundle)
        let arpItems = try aprClient.executeARPQuery()
        let macAddresses = Set(info.metadata.network.flatMap { $0.devices.map(\.value.MACAddress) } ?? [])
        let filteredArpaRows = arpItems.filter { macAddresses.contains($0.macAddress) }

        let item = Item(info: info, arp: filteredArpaRows)

        switch context.format {
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
