import Foundation

struct VMState: Equatable, Codable {
    struct NetworkDevice: Equatable, Codable {
        let MACAddress: String
    }

    struct Network: Equatable, Codable {
        var devices: [Int: NetworkDevice] = [:]
    }

    var id: ImageID
    var createdAt: Date
    var network: Network?
}

extension VMState: CustomStringConvertible {
    public var description: String {
        """
        State:
          id: \(id.description)
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

extension [Int: VMState.NetworkDevice] {
    var description: String {
        let prefix = "      "
        return sorted { $0.key < $1.key }.map { index, value in
            """
            \(prefix)index: \(index)
            \(prefix)macAddress: \(value.MACAddress)
            """
        }.joined(separator: "\n\n")
    }
}
