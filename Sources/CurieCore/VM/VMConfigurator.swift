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
import TSCBasic
import Virtualization

struct VMSpec {
    var reference: ImageReference
    var restoreImagePath: AbsolutePath
    var diskSize: MemorySize
    var configPath: AbsolutePath?
}

protocol VMConfigurator {
    func createVM(with bundle: VMBundle, spec: VMSpec) async throws
    func loadVM(with bundle: VMBundle, overrideConfig: VMPartialConfig?) throws -> VM
}

final class DefaultVMConfigurator: VMConfigurator {
    private let bundleParser: VMBundleParser
    private let fileSystem: CurieCommon.FileSystem
    private let wallClock: WallClock
    private let console: Console

    init(
        bundleParser: VMBundleParser,
        fileSystem: CurieCommon.FileSystem,
        wallClock: WallClock,
        console: Console
    ) {
        self.bundleParser = bundleParser
        self.fileSystem = fileSystem
        self.wallClock = wallClock
        self.console = console
    }

    func createVM(with bundle: VMBundle, spec: VMSpec) async throws {
        guard !fileSystem.exists(at: bundle.path) else {
            throw CoreError.generic("Failed to create new VM at path '\(bundle.path)', bundle already exists")
        }

        // Create basic VM directory stricture
        try fileSystem.createDirectory(at: bundle.path)

        // Create config file
        try createConfig(bundle: bundle, sourcePath: spec.configPath)

        // Create metadata file
        try createMetadata(bundle: bundle, reference: spec.reference)

        // Create disk image
        try createDiskImage(atPath: bundle.diskImage, size: spec.diskSize)

        // Create platform configuration
        let restoreImage = try await loadRestoreImage(spec: spec)
        try createPlatformConfiguration(bundle: bundle, restoreImage: restoreImage)
    }

    func loadVM(with bundle: VMBundle, overrideConfig: VMPartialConfig?) throws -> VM {
        let config = try bundleParser.readConfig(from: bundle, overrideConfig: overrideConfig)
        let metadata = try bundleParser.readMetadata(from: bundle)
        let vm = try VZVirtualMachine(configuration: makeConfiguration(bundle: bundle, config: config))
        return VM(
            vm: vm,
            config: config,
            metadata: metadata,
            console: console
        )
    }

    // MARK: - Private

    private func makeConfiguration(
        bundle: VMBundle,
        config: VMConfig
    ) throws -> VZVirtualMachineConfiguration {
        let configuration = VZVirtualMachineConfiguration()
        configuration.platform = try bundleParser.readPlatformConfiguration(from: bundle)
        configuration.bootLoader = prepareBootLoader()
        configuration.cpuCount = config.cpuCount
        configuration.memorySize = config.memorySize.bytes
        configuration.graphicsDevices = prepareGraphicsDeviceConfigurations(config: config)
        configuration.storageDevices = try prepareStorageDeviceConfigurations(with: bundle)
        configuration.directorySharingDevices = try prepareDirectorySharingDevices(config: config)
        configuration.networkDevices = try prepareNetworkDeviceConfigurations(with: bundle, config: config)
        configuration.pointingDevices = preparePointingDeviceConfigurations()
        configuration.keyboards = prepareKeyboardConfigurations()
        try configuration.validate()
        if #available(macOS 14.0, *) {
            try configuration.validateSaveRestoreSupport()
        }

        return configuration
    }

    private func prepareBootLoader() -> VZBootLoader {
        VZMacOSBootLoader()
    }

    private func prepareGraphicsDeviceConfigurations(config: VMConfig) -> [VZGraphicsDeviceConfiguration] {
        let graphicsConfiguration = VZMacGraphicsDeviceConfiguration()
        graphicsConfiguration.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: config.display.width,
                heightInPixels: config.display.height,
                pixelsPerInch: config.display.pixelsPerInch
            ),
        ]

        return [graphicsConfiguration]
    }

    private func prepareStorageDeviceConfigurations(with bundle: VMBundle) throws
        -> [VZStorageDeviceConfiguration] {
        let diskImageAttachment = try VZDiskImageStorageDeviceAttachment(url: bundle.diskImage.asURL, readOnly: false)
        return [VZVirtioBlockDeviceConfiguration(attachment: diskImageAttachment)]
    }

    private func prepareDirectorySharingDevices(config: VMConfig) throws -> [VZDirectorySharingDeviceConfiguration] {
        let automount = config.sharedDirectory.automount ?? true
        let configuration = VZVirtioFileSystemDeviceConfiguration(
            tag: automount ? VZVirtioFileSystemDeviceConfiguration.macOSGuestAutomountTag : "curie"
        )

        let directories = config.sharedDirectory.directories.map { directory in
            switch directory {
            case let .currentWorkingDirectory(options):
                let currentWorkingDirectoryURL = fileSystem.currentWorkingDirectory.asURL
                let sharedDirectory = VZSharedDirectory(url: currentWorkingDirectoryURL, readOnly: options.readOnly)
                return (options.name, sharedDirectory)
            case let .directory(options):
                let url = URL(fileURLWithPath: options.path)
                let sharedDirectory = VZSharedDirectory(url: url, readOnly: options.readOnly)
                return (options.name, sharedDirectory)
            }
        }
        let directoriesDictionary = Dictionary(directories, uniquingKeysWith: { first, _ in first })
        let share = VZMultipleDirectoryShare(directories: directoriesDictionary)

        configuration.share = share
        return [configuration]
    }

    private func prepareNetworkDeviceConfigurations(
        with bundle: VMBundle,
        config: VMConfig
    ) throws -> [VZNetworkDeviceConfiguration] {
        try config.network.devices.enumerated().map { index, device in
            let networkDevice = VZVirtioNetworkDeviceConfiguration()
            switch device.macAddress {
            case .automatic:
                guard config.shutdown.behaviour != .pause else {
                    throw CoreError
                        .generic(
                            "Failed to set up network device. Shutdown 'pause' behaviour requires 'manual' MAC address."
                        )
                }
            case .synthesized:
                guard config.shutdown.behaviour != .pause else {
                    throw CoreError
                        .generic(
                            "Failed to set up network device. Shutdown 'pause' behaviour requires 'manual' MAC address."
                        )
                }
                var metadata = try bundleParser.readMetadata(from: bundle)
                let macAddress = VZMACAddress.randomLocallyAdministered()
                var network = metadata.network ?? VMMetadata.Network()
                network.devices[index] = .init(MACAddress: macAddress.string)
                metadata.network = network
                try bundleParser.writeMetadata(metadata, toBundle: bundle)

                networkDevice.macAddress = macAddress
            case let .manual(MACAddress: string):
                guard let macAddress = VZMACAddress(string: string) else {
                    throw CoreError.generic("Invalid MAC Address '\(string)'")
                }
                networkDevice.macAddress = macAddress
            }
            switch device.mode {
            case .NAT:
                let networkAttachment = VZNATNetworkDeviceAttachment()
                networkDevice.attachment = networkAttachment
            }
            return networkDevice
        }
    }

    private func preparePointingDeviceConfigurations() -> [VZPointingDeviceConfiguration] {
        [VZMacTrackpadConfiguration()]
    }

    private func prepareKeyboardConfigurations() -> [VZKeyboardConfiguration] {
        if #available(macOS 14.0, *) {
            [VZMacKeyboardConfiguration()]
        } else {
            [VZUSBKeyboardConfiguration()]
        }
    }

    private func createDiskImage(atPath path: AbsolutePath, size: MemorySize) throws {
        let diskFd = open(path.pathString, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        if diskFd == -1 {
            throw CoreError.generic("Failed to create disk image at path '\(path)'")
        }

        var result = ftruncate(diskFd, Int64(size.bytes))
        if result != 0 {
            throw CoreError.generic("Failed to allocate \(size) of space for disk image at path '\(path)'")
        }

        result = close(diskFd)
        if result != 0 {
            throw CoreError.generic("Failed to close disk image at path '\(path)'")
        }
    }

    private func createConfig(bundle: VMBundle, sourcePath: AbsolutePath?) throws {
        guard let sourcePath else {
            try bundleParser.writeConfig(Constants.defaultConfig, toBundle: bundle)
            return
        }
        guard bundleParser.canParseConfig(at: sourcePath) else {
            throw CoreError.generic("Failed to parse config at path '\(sourcePath)'")
        }
        try fileSystem.move(from: sourcePath, to: bundle.config)
    }

    private func createMetadata(bundle: VMBundle, reference: ImageReference) throws {
        try bundleParser.writeMetadata(.init(
            id: reference.id,
            createdAt: wallClock.now()
        ), toBundle: bundle)
    }

    private func loadRestoreImage(spec: VMSpec) async throws -> VZMacOSRestoreImage {
        try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.load(from: spec.restoreImagePath.asURL) { result in
                switch result {
                case let .success(restoreImage):
                    continuation.resume(returning: restoreImage)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func createPlatformConfiguration(bundle: VMBundle, restoreImage: VZMacOSRestoreImage) throws {
        guard let macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw CoreError.generic("No supported configuration is available")
        }

        if !macOSConfiguration.hardwareModel.isSupported {
            throw CoreError.generic("Configuration is not supported on the current host")
        }

        let configuration = VZMacPlatformConfiguration()
        do {
            let auxiliaryStorage = try VZMacAuxiliaryStorage(
                creatingStorageAt: bundle.auxilaryStorage.asURL,
                hardwareModel: macOSConfiguration.hardwareModel,
                options: []
            )
            configuration.auxiliaryStorage = auxiliaryStorage
            configuration.hardwareModel = macOSConfiguration.hardwareModel
            configuration.machineIdentifier = VZMacMachineIdentifier()
        } catch {
            throw CoreError.generic("Failed to create PlatformConfiguration. \(error)")
        }

        try fileSystem.write(data: configuration.hardwareModel.dataRepresentation, to: bundle.hardwareModel)
        try fileSystem.write(data: configuration.machineIdentifier.dataRepresentation, to: bundle.machineIdentifier)
    }
}
