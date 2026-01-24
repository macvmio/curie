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
    var sharedDirectory: VMConfig.SharedDirectoryConfig?
    var shutdown: VMConfig.ShutdownConfig?
    var clipboard: VMConfig.ClipboardConfig?

    func merge(config: VMPartialConfig) -> VMPartialConfig {
        let network = VMConfig.NetworkConfig(devices: (config.network?.devices ?? []) + (network?.devices ?? []))
        let sharedDirectory: VMConfig.SharedDirectoryConfig = .init(
            automount: config.sharedDirectory?.automount ?? sharedDirectory?.automount,
            directories: (config.sharedDirectory?.directories ?? []) + (sharedDirectory?.directories ?? [])
        )

        return .init(
            cpuCount: config.cpuCount ?? cpuCount,
            memorySize: config.memorySize ?? memorySize,
            display: config.display ?? display,
            network: network,
            sharedDirectory: sharedDirectory,
            shutdown: config.shutdown ?? shutdown,
            clipboard: config.clipboard ?? clipboard
        )
    }
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
        static let minPixelsPerInch = 72

        var width: Int
        var height: Int
        var pixelsPerInch: Int
    }

    struct NetworkConfig: Equatable, Codable {
        enum MACAddress: Equatable, Codable {
            case manual(MACAddress: String)
            case automatic
            case synthesized

            init(from decoder: Decoder) throws {
                let value = try decoder.singleValueContainer().decode(String.self)
                switch value {
                case "automatic":
                    self = .automatic
                case "synthesized":
                    self = .synthesized
                default:
                    self = .manual(MACAddress: value)
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .automatic:
                    try container.encode("automatic")
                case .synthesized:
                    try container.encode("synthesized")
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

    struct SharedDirectoryConfig: Equatable, Codable {
        struct CurrentWorkingDirectoryOptions: Equatable, Codable {
            let name: String
            let readOnly: Bool

            init(name: String = "cwd", readOnly: Bool = false) {
                self.name = name
                self.readOnly = readOnly
            }
        }

        struct DirectoryOptions: Equatable, Codable {
            let path: String
            let name: String
            let readOnly: Bool

            init(path: String, name: String, readOnly: Bool = false) {
                self.path = path
                self.name = name
                self.readOnly = readOnly
            }
        }

        enum Directory: Equatable, Codable {
            case currentWorkingDirectory(options: CurrentWorkingDirectoryOptions)
            case directory(options: DirectoryOptions)
        }

        var automount: Bool?
        var directories: [Directory]
    }

    struct ShutdownConfig: Equatable, Codable {
        enum ShutdownBehaviour: Equatable, Codable {
            case stop
            case pause
        }

        var behaviour: ShutdownBehaviour
    }

    struct ClipboardConfig: Equatable, Codable {
        var enabled: Bool
    }

    var cpuCount: Int
    var memorySize: MemorySize
    var display: DisplayConfig
    var network: NetworkConfig
    var sharedDirectory: SharedDirectoryConfig
    var shutdown: ShutdownConfig
    var clipboard: ClipboardConfig
}

extension VMConfig: CustomStringConvertible {
    public var description: String {
        """
        Config:
          cpuCount: \(cpuCount)
          memorySize: \(memorySize)
          display:
            width: \(display.width)px
            height: \(display.height)px
            pixelsPerInch: \(display.pixelsPerInch)
          network:
            devices:
        \(network.devices.description)
          sharedDirectory:
            automount: \(sharedDirectory.automount?.description ?? "undefined")
            directories:
        \(sharedDirectory.directories.description)
          shutdown:
            behaviour: \(shutdown.behaviour.description)
          clipboard:
            enabled: \(clipboard.enabled)
        """
    }
}

extension [VMConfig.NetworkConfig.Device] {
    var description: String {
        let prefix = "      "
        guard !isEmpty else {
            return "\(prefix)N/A"
        }
        return enumerated().map { index, value in
            """
            \(prefix)index: \(index)
            \(prefix)macAddress: \(value.macAddress)
            \(prefix)mode: \(value.mode)
            """
        }.joined(separator: "\n\n")
    }
}

extension [VMConfig.SharedDirectoryConfig.Directory] {
    var description: String {
        let prefix = "      "
        guard !isEmpty else {
            return "\(prefix)N/A"
        }
        return enumerated().map { _, value in
            switch value {
            case let .currentWorkingDirectory(options: options):
                """
                \(prefix)type: currentWorkingDirectory
                \(prefix)name: \(options.name)
                \(prefix)readOnly: \(options.readOnly)
                """
            case let .directory(options: options):
                """
                \(prefix)type: directory
                \(prefix)path: \(options.path)
                \(prefix)name: \(options.name)
                \(prefix)readOnly: \(options.readOnly)
                """
            }
        }.joined(separator: "\n\n")
    }
}

extension VMConfig.ShutdownConfig.ShutdownBehaviour: CustomStringConvertible {
    var description: String {
        switch self {
        case .stop:
            "exit"
        case .pause:
            "pause"
        }
    }
}

// swiftlint:enable nesting
