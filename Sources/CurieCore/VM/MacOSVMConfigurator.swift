import CurieCommon
import Foundation
import TSCBasic
import Virtualization

struct MacOSVMSpec {
    var restoreImagePath: AbsolutePath
    var diskSize: MemorySize
    var configPath: AbsolutePath?
}

protocol MacOSVMConfigurator {
    func createVM(with bundle: MacOSVMBundle, spec: MacOSVMSpec) async throws
    func loadVM(with bundle: MacOSVMBundle) throws -> MacOSVM
}

final class DefaultMacOSMVConfigurator: MacOSVMConfigurator {
    private let bundleParser: MacOSVMBundleParser
    private let fileSystem: CurieCommon.FileSystem
    private let virtualMachineDelegate: MacOSVirtualMachineDelegate
    private let console: Console

    init(
        bundleParser: MacOSVMBundleParser,
        fileSystem: CurieCommon.FileSystem,
        virtualMachineDelegate: MacOSVirtualMachineDelegate,
        console: Console
    ) {
        self.bundleParser = bundleParser
        self.fileSystem = fileSystem
        self.console = console
        self.virtualMachineDelegate = virtualMachineDelegate
    }

    func createVM(with bundle: MacOSVMBundle, spec: MacOSVMSpec) async throws {
        console.text("Create VM")

        guard !fileSystem.exists(at: bundle.path) else {
            throw CoreError.generic("Failed to create new VM at path '\(bundle.path)', bundle already exists")
        }

        // Create basic VM directory stricture
        try fileSystem.createDirectory(at: bundle.path)

        // Verify config file
        try createConfig(bundle: bundle, sourcePath: spec.configPath)

        // Create disk image
        try createDiskImage(
            atPath: bundle.diskImage,
            size: spec.diskSize
        )

        // Create platform configuration
        let restoreImage = try await loadRestoreImage(spec: spec)
        try createPlatformConfiguration(bundle: bundle, restoreImage: restoreImage)
    }

    func loadVM(with bundle: MacOSVMBundle) throws -> MacOSVM {
        console.text("Load VM")

        let config = try bundleParser.readConfig(from: bundle)
        let vm = try VZVirtualMachine(configuration: makeConfiguration(bundle: bundle, config: config))

        vm.delegate = virtualMachineDelegate

        return MacOSVM(
            vm: vm,
            config: config,
            console: console
        )
    }

    // MARK: - Private

    private func makeConfiguration(
        bundle: MacOSVMBundle,
        config: MacOSVMConfig
    ) throws -> VZVirtualMachineConfiguration {
        let configuration = VZVirtualMachineConfiguration()
        configuration.platform = try bundleParser.readPlatformConfiguration(from: bundle)
        configuration.bootLoader = prepareBootLoader()
        configuration.cpuCount = config.cpuCount
        configuration.memorySize = config.memorySize.bytes
        configuration.graphicsDevices = prepareGraphicsDeviceConfigurations(config: config)
        configuration.storageDevices = try prepareStorageDeviceConfigurations(with: bundle)
        configuration.networkDevices = try prepareNetworkDeviceConfigurations(config: config)
        configuration.pointingDevices = preparePointingDeviceConfigurations()
        configuration.keyboards = prepareKeyboardConfigurations()
        try configuration.validate()

        return configuration
    }

    private func prepareBootLoader() -> VZBootLoader {
        VZMacOSBootLoader()
    }

    private func prepareGraphicsDeviceConfigurations(config: MacOSVMConfig) -> [VZGraphicsDeviceConfiguration] {
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

    private func prepareStorageDeviceConfigurations(with bundle: MacOSVMBundle) throws
        -> [VZStorageDeviceConfiguration] {
        let diskImageAttachment = try VZDiskImageStorageDeviceAttachment(url: bundle.diskImage.asURL, readOnly: false)
        return [VZVirtioBlockDeviceConfiguration(attachment: diskImageAttachment)]
    }

    private func prepareNetworkDeviceConfigurations(config: MacOSVMConfig) throws -> [VZNetworkDeviceConfiguration] {
        try config.network.devices.map { device in
            let networkDevice = VZVirtioNetworkDeviceConfiguration()
            switch device.macAddress {
            case .automatic:
                break
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
        [VZUSBKeyboardConfiguration()]
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

    private func createConfig(bundle: MacOSVMBundle, sourcePath: AbsolutePath?) throws {
        guard let sourcePath else {
            try bundleParser.writeConfig(Constants.defaultConfig, toBundle: bundle)
            return
        }
        guard bundleParser.canParseConfig(at: sourcePath) else {
            throw CoreError.generic("Failed to parse config at path '\(sourcePath)'")
        }
        try fileSystem.move(from: sourcePath, to: bundle.config)
    }

    private func loadRestoreImage(spec: MacOSVMSpec) async throws -> VZMacOSRestoreImage {
        let restoreImage = try await withCheckedContinuation { continuation in
            VZMacOSRestoreImage.load(
                from: spec.restoreImagePath.asURL,
                completionHandler: continuation.resume(returning:)
            )
        }.get()

        return restoreImage
    }

    private func createPlatformConfiguration(bundle: MacOSVMBundle, restoreImage: VZMacOSRestoreImage) throws {
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