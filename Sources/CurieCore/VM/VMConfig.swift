import CurieCommon
import Foundation

// swiftlint:disable nesting

public struct VMPartialConfig: Equatable, Codable {
    struct DisplayPartialConfig: Equatable, Codable {
        var width: Int?
        var height: Int?
        var pixelsPerInch: Int?
    }

    var cpuCount: VMConfig.CPUConfig?
    var memorySize: VMConfig.MemoryConfig?
    var display: DisplayPartialConfig?
    var network: VMConfig.NetworkConfig?
}

public struct VMConfig: Equatable, Codable {
    enum CPUConfig: Equatable, Codable {
        case manual(CPUCount: Int)
        case minimumAllowedCPUCount
        case maximumAllowedCPUCount

        init(from decoder: Decoder) throws {
            if let value = try? decoder.singleValueContainer().decode(String.self) {
                if value == "minimumAllowedCPUCount" {
                    self = .minimumAllowedCPUCount
                    return
                }
                if value == "maximumAllowedCPUCount" {
                    self = .maximumAllowedCPUCount
                    return
                }
            }
            guard let value = try? decoder.singleValueContainer().decode(Int.self) else {
                throw CoreError.generic("Failed to read cpu count config")
            }
            self = .manual(CPUCount: value)
        }
    }

    enum MemoryConfig: Equatable, Codable {
        case manual(memorySize: MemorySize)
        case minimumAllowedMemorySize
        case maximumAllowedMemorySize

        init(from decoder: Decoder) throws {
            if let value = try? decoder.singleValueContainer().decode(String.self) {
                if value == "minimumAllowedMemorySize" {
                    self = .minimumAllowedMemorySize
                    return
                }
                if value == "maximumAllowedMemorySize" {
                    self = .maximumAllowedMemorySize
                    return
                }
            }
            guard let value = try? decoder.singleValueContainer().decode(MemorySize.self) else {
                throw CoreError.generic("Failed to read memory size config")
            }
            self = .manual(memorySize: value)
        }
    }

    struct DisplayConfig: Equatable, Codable {
        static let maxWidth = 3840
        static let maxHeight = 2160
        static let maxPixelsPerInch = 218

        static let minWidth = 640
        static let minHeight = 480
        static let minPixelsPerInch = 80

        var width: Int
        var height: Int
        var pixelsPerInch: Int
    }

    struct NetworkConfig: Equatable, Codable {
        enum MACAddress: Equatable, Codable {
            case manual(MACAddress: String)
            case automatic

            init(from decoder: Decoder) throws {
                let value = try decoder.singleValueContainer().decode(String.self)
                switch value {
                case "automatic":
                    self = .automatic
                default:
                    self = .manual(MACAddress: value)
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .automatic:
                    try container.encode("automatic")
                case let .manual(MACAddress: macAddress):
                    try container.encode(macAddress)
                }
            }
        }

        enum Mode: String, Equatable, Codable {
            case NAT
        }

        struct Device: Equatable, Codable {
            var macAddress: MACAddress
            var mode: Mode
        }

        var devices: [Device]
    }

    var name: String
    var cpuCount: Int
    var memorySize: MemorySize
    var display: DisplayConfig
    var network: NetworkConfig
}

extension VMConfig: CustomStringConvertible {
    public var description: String {
        """
        Config:
          name: \(name)
          cpuCount: \(cpuCount)
          memorySize: \(memorySize)
          display:
            width: \(display.width)px
            height: \(display.height)px
            pixelsPerInch: \(display.pixelsPerInch)
          network:
            devices:
        \(network.devices.description)
        """
    }
}

extension [VMConfig.NetworkConfig.Device] {
    var description: String {
        let prefix = "      "
        return enumerated().map { index, value in
            """
            \(prefix)index: \(index + 1)
            \(prefix)macAddress: \(value.macAddress)
            \(prefix)mode: \(value.mode)
            """
        }.joined(separator: "\n\n")
    }
}

// swiftlint:enable nesting
