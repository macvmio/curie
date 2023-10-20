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
