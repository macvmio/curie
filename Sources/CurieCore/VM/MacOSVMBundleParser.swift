import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol MacOSVMBundleParser {
    func readPlatformConfiguration(from bundle: MacOSVMBundle) throws -> VZMacPlatformConfiguration
    func readConfig(from bundle: MacOSVMBundle) throws -> MacOSVMConfig
    func writeConfig(_ config: MacOSVMConfig, toBundle bundle: MacOSVMBundle) throws
    func canParseConfig(at path: AbsolutePath) -> Bool
}

final class DefaultMacOSVMBundleParser: MacOSVMBundleParser {
    private let fileSystem: CurieCommon.FileSystem
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private let defaultConfig = Constants.defaultConfig

    init(fileSystem: CurieCommon.FileSystem) {
        self.fileSystem = fileSystem
    }

    func writePlatformConfiguration(from _: MacOSVMBundle) throws {}

    func readPlatformConfiguration(from bundle: MacOSVMBundle) throws -> VZMacPlatformConfiguration {
        try validateBundle(bundle: bundle)

        let configuration = VZMacPlatformConfiguration()
        configuration.auxiliaryStorage = try readAuxilaryStorage(from: bundle)
        configuration.hardwareModel = try readHardwareModel(from: bundle)
        configuration.machineIdentifier = try readMachineIdentifier(from: bundle)
        return configuration
    }

    func readConfig(from bundle: MacOSVMBundle) throws -> MacOSVMConfig {
        let data = try fileSystem.read(from: bundle.config)
        let partialConfig = try jsonDecoder.decode(MacOSVMPartialConfig.self, from: data)
        let config = MacOSVMConfig(
            name: bundle.name,
            cpuCount: prepareCPUCount(config: partialConfig),
            memorySize: prepareMemorySize(config: partialConfig),
            display: prepareDisplay(config: partialConfig),
            network: prepareNetwork(config: partialConfig)
        )
        return config
    }

    func writeConfig(_ config: MacOSVMConfig, toBundle bundle: MacOSVMBundle) throws {
        let data = try jsonEncoder.encode(config)
        try fileSystem.write(data: data, to: bundle.config)
    }

    func canParseConfig(at path: AbsolutePath) -> Bool {
        do {
            let data = try Data(contentsOf: path.asURL)
            _ = try jsonDecoder.decode(MacOSVMPartialConfig.self, from: data)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func readAuxilaryStorage(from bundle: MacOSVMBundle) throws -> VZMacAuxiliaryStorage {
        guard fileSystem.exists(at: bundle.auxilaryStorage) else {
            throw CoreError
                .generic("VM Bundle does not contain auxilary storage file at path '\(bundle.auxilaryStorage)'")
        }
        return VZMacAuxiliaryStorage(contentsOf: bundle.auxilaryStorage.asURL)
    }

    private func readHardwareModel(from bundle: MacOSVMBundle) throws -> VZMacHardwareModel {
        guard fileSystem.exists(at: bundle.hardwareModel) else {
            throw CoreError.generic("VM Bundle does not contain hardware model file at path '\(bundle.hardwareModel)'")
        }
        guard let hardwareModelData = try? Data(contentsOf: bundle.hardwareModel.asURL) else {
            throw CoreError.generic("Failed to read hardware model data at path '\(bundle.hardwareModel)'")
        }
        guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData) else {
            throw CoreError.generic("Failed to parse hardware model data at path '\(bundle.hardwareModel)'")
        }
        guard hardwareModel.isSupported else {
            throw CoreError
                .generic("Hardware model data at path '\(bundle.hardwareModel)' is not supported on the current host")
        }
        return hardwareModel
    }

    private func readMachineIdentifier(from bundle: MacOSVMBundle) throws -> VZMacMachineIdentifier {
        guard fileSystem.exists(at: bundle.machineIdentifier) else {
            throw CoreError
                .generic("VM Bundle does not contain machine identifier file at path '\(bundle.machineIdentifier)'")
        }
        guard let machineIdentifierData = try? Data(contentsOf: bundle.machineIdentifier.asURL) else {
            throw CoreError.generic("Failed to read machine identifier data at path '\(bundle.machineIdentifier)'")
        }
        guard let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machineIdentifierData) else {
            throw CoreError.generic("Failed to parse machine identifier data at path '\(bundle.machineIdentifier)'")
        }
        return machineIdentifier
    }

    // MARK: - Private

    private func validateBundle(bundle: MacOSVMBundle) throws {
        guard fileSystem.exists(at: bundle.path) else {
            throw CoreError.generic("VM Bundle does not exist at path '\(bundle.path)'")
        }
    }

    private func prepareCPUCount(config: MacOSVMPartialConfig) -> Int {
        let normalize: (Int) -> Int = { count in
            var result = count
            result = max(result, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
            result = min(result, VZVirtualMachineConfiguration.maximumAllowedCPUCount)
            return result
        }

        switch config.cpu {
        case let .manual(CPUCount: count):
            return normalize(count)
        case .maximumAllowedCPUCount:
            return normalize(ProcessInfo.processInfo.processorCount)
        case .minimumAllowedCPUCount:
            return VZVirtualMachineConfiguration.maximumAllowedCPUCount
        case .none:
            return normalize(defaultConfig.cpuCount)
        }
    }

    private func prepareMemorySize(config: MacOSVMPartialConfig) -> MemorySize {
        let normalize: (UInt64) -> UInt64 = { size in
            var result = size
            result = max(result, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
            result = min(result, VZVirtualMachineConfiguration.maximumAllowedMemorySize)
            return result
        }

        switch config.memory {
        case let .manual(memorySize: size):
            return MemorySize(bytes: normalize(size.bytes))
        case .maximumAllowedMemorySize:
            return MemorySize(bytes: VZVirtualMachineConfiguration.maximumAllowedMemorySize)
        case .minimumAllowedMemorySize:
            return MemorySize(bytes: VZVirtualMachineConfiguration.minimumAllowedMemorySize)
        case .none:
            return MemorySize(bytes: normalize(defaultConfig.memorySize.bytes))
        }
    }

    private func prepareDisplay(config: MacOSVMPartialConfig) -> MacOSVMConfig.DisplayConfig {
        let display = MacOSVMConfig.DisplayConfig(
            width: config.display?.width ?? defaultConfig.display.width,
            height: config.display?.height ?? defaultConfig.display.height,
            pixelsPerInch: config.display?.pixelsPerInch ?? defaultConfig.display.pixelsPerInch
        )
        return .init(
            width: max(
                min(display.width, MacOSVMConfig.DisplayConfig.maxWidth),
                MacOSVMConfig.DisplayConfig.minWidth
            ),
            height: max(
                min(display.height, MacOSVMConfig.DisplayConfig.maxHeight),
                MacOSVMConfig.DisplayConfig.minHeight
            ),
            pixelsPerInch: max(
                min(display.pixelsPerInch, MacOSVMConfig.DisplayConfig.maxPixelsPerInch),
                MacOSVMConfig.DisplayConfig.minPixelsPerInch
            )
        )
    }

    private func prepareNetwork(config: MacOSVMPartialConfig) -> MacOSVMConfig.NetworkConfig {
        config.network ?? defaultConfig.network
    }
}
