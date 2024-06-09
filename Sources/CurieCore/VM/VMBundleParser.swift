import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol VMBundleParser {
    func readPlatformConfiguration(from bundle: VMBundle) throws -> VZMacPlatformConfiguration
    func readConfig(from bundle: VMBundle) throws -> VMConfig
    func readConfig(from bundle: VMBundle, overrideConfig: VMPartialConfig?) throws -> VMConfig
    func writeConfig(_ config: VMConfig, toBundle bundle: VMBundle) throws
    func canParseConfig(at path: AbsolutePath) -> Bool
    func readMetadata(from bundle: VMBundle) throws -> VMMetadata
    func writeMetadata(_ metadata: VMMetadata, toBundle bundle: VMBundle) throws
    func updateMetadata(bundle: VMBundle, closure: (inout VMMetadata) throws -> Void) throws
    func readInfo(from bundle: VMBundle) throws -> VMInfo
}

final class DefaultVMBundleParser: VMBundleParser {
    private let fileSystem: CurieCommon.FileSystem
    private let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let defaultConfig = Constants.defaultConfig

    init(fileSystem: CurieCommon.FileSystem) {
        self.fileSystem = fileSystem
    }

    func writePlatformConfiguration(from _: VMBundle) throws {}

    func readPlatformConfiguration(from bundle: VMBundle) throws -> VZMacPlatformConfiguration {
        try validateBundle(bundle: bundle)

        let configuration = VZMacPlatformConfiguration()
        configuration.auxiliaryStorage = try readAuxilaryStorage(from: bundle)
        configuration.hardwareModel = try readHardwareModel(from: bundle)
        configuration.machineIdentifier = try readMachineIdentifier(from: bundle)
        return configuration
    }

    func readConfig(from bundle: VMBundle) throws -> VMConfig {
        let data = try fileSystem.read(from: bundle.config)
        let partialConfig = try jsonDecoder.decode(VMPartialConfig.self, from: data)
        let config = prepareConfig(partialConfig: partialConfig)
        return config
    }

    func readConfig(from bundle: VMBundle, overrideConfig: VMPartialConfig?) throws -> VMConfig {
        let data = try fileSystem.read(from: bundle.config)
        let diskConfig = try jsonDecoder.decode(VMPartialConfig.self, from: data)
        let partialConfig: VMPartialConfig = if let overrideConfig {
            diskConfig.merge(config: overrideConfig)
        } else {
            diskConfig
        }
        let config = prepareConfig(partialConfig: partialConfig)
        return config
    }

    func writeConfig(_ config: VMConfig, toBundle bundle: VMBundle) throws {
        let data = try jsonEncoder.encode(config)
        try fileSystem.write(data: data, to: bundle.config)
    }

    func canParseConfig(at path: AbsolutePath) -> Bool {
        do {
            let data = try Data(contentsOf: path.asURL)
            _ = try jsonDecoder.decode(VMPartialConfig.self, from: data)
            return true
        } catch {
            return false
        }
    }

    func readMetadata(from bundle: VMBundle) throws -> VMMetadata {
        let data = try fileSystem.read(from: bundle.metadata)
        let state = try jsonDecoder.decode(VMMetadata.self, from: data)
        return state
    }

    func writeMetadata(_ metadata: VMMetadata, toBundle bundle: VMBundle) throws {
        let data = try jsonEncoder.encode(metadata)
        try fileSystem.write(data: data, to: bundle.metadata)
    }

    func updateMetadata(bundle: VMBundle, closure: (inout VMMetadata) throws -> Void) throws {
        var metadata = try readMetadata(from: bundle)
        try closure(&metadata)
        try writeMetadata(metadata, toBundle: bundle)
    }

    func readInfo(from bundle: VMBundle) throws -> VMInfo {
        let config = try readConfig(from: bundle)
        let metadata = try readMetadata(from: bundle)
        return VMInfo(config: config, metadata: metadata)
    }

    // MARK: - Private

    private func readAuxilaryStorage(from bundle: VMBundle) throws -> VZMacAuxiliaryStorage {
        guard fileSystem.exists(at: bundle.auxilaryStorage) else {
            throw CoreError
                .generic("VM Bundle does not contain auxilary storage file at path '\(bundle.auxilaryStorage)'")
        }
        return VZMacAuxiliaryStorage(contentsOf: bundle.auxilaryStorage.asURL)
    }

    private func readHardwareModel(from bundle: VMBundle) throws -> VZMacHardwareModel {
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

    private func readMachineIdentifier(from bundle: VMBundle) throws -> VZMacMachineIdentifier {
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

    private func validateBundle(bundle: VMBundle) throws {
        guard fileSystem.exists(at: bundle.path) else {
            throw CoreError.generic("VM Bundle does not exist at path '\(bundle.path)'")
        }
    }

    private func prepareConfig(partialConfig: VMPartialConfig) -> VMConfig {
        VMConfig(
            cpuCount: prepareCPUCount(config: partialConfig),
            memorySize: prepareMemorySize(config: partialConfig),
            display: prepareDisplay(config: partialConfig),
            network: prepareNetwork(config: partialConfig),
            sharedDirectory: prepareSharedDirectory(config: partialConfig),
            shutdown: prepareShutdown(config: partialConfig)
        )
    }

    private func prepareCPUCount(config: VMPartialConfig) -> Int {
        let normalize: (Int) -> Int = { count in
            var result = count
            result = max(result, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
            result = min(result, VZVirtualMachineConfiguration.maximumAllowedCPUCount)
            return result
        }

        switch config.cpuCount {
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

    private func prepareMemorySize(config: VMPartialConfig) -> MemorySize {
        let normalize: (UInt64) -> UInt64 = { size in
            var result = size
            result = max(result, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
            result = min(result, VZVirtualMachineConfiguration.maximumAllowedMemorySize)
            return result
        }

        switch config.memorySize {
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

    private func prepareDisplay(config: VMPartialConfig) -> VMConfig.DisplayConfig {
        let display = VMConfig.DisplayConfig(
            width: config.display?.width ?? defaultConfig.display.width,
            height: config.display?.height ?? defaultConfig.display.height,
            pixelsPerInch: config.display?.pixelsPerInch ?? defaultConfig.display.pixelsPerInch
        )
        return .init(
            width: max(
                min(display.width, VMConfig.DisplayConfig.maxWidth),
                VMConfig.DisplayConfig.minWidth
            ),
            height: max(
                min(display.height, VMConfig.DisplayConfig.maxHeight),
                VMConfig.DisplayConfig.minHeight
            ),
            pixelsPerInch: max(
                min(display.pixelsPerInch, VMConfig.DisplayConfig.maxPixelsPerInch),
                VMConfig.DisplayConfig.minPixelsPerInch
            )
        )
    }

    private func prepareNetwork(config: VMPartialConfig) -> VMConfig.NetworkConfig {
        config.network ?? defaultConfig.network
    }

    private func prepareSharedDirectory(config: VMPartialConfig) -> VMConfig.SharedDirectoryConfig {
        config.sharedDirectory ?? defaultConfig.sharedDirectory
    }

    private func prepareShutdown(config: VMPartialConfig) -> VMConfig.ShutdownConfig {
        config.shutdown ?? defaultConfig.shutdown
    }
}
