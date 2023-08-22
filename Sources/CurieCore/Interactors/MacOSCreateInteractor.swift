import CurieCommon
import Foundation
import TSCBasic

public struct MacOSCreateInteractorContext {
    public enum Source {
        case latest
        case ipsw(path: String)
    }

    var source: Source
    var vmPath: String?
    var diskSize: String?
    var configPath: String?

    public init(
        source: Source,
        vmPath: String?,
        diskSize: String?,
        configPath: String?
    ) {
        self.source = source
        self.vmPath = vmPath
        self.diskSize = diskSize
        self.configPath = configPath
    }
}

public protocol MacOSCreateInteractor {
    func execute(with context: MacOSCreateInteractorContext) throws
}

final class DefaultMacOSCreateInteractor: MacOSCreateInteractor {
    private let downloader: MacOSRestoreImageDownloader
    private let configurator: MacOSVMConfigurator
    private let installer: MacOSVMInstaller
    private let system: System
    private let fileSystem: CurieCommon.FileSystem
    private let console: Console

    init(
        downloader: MacOSRestoreImageDownloader,
        configurator: MacOSVMConfigurator,
        installer: MacOSVMInstaller,
        system: System,
        fileSystem: CurieCommon.FileSystem,
        console: Console
    ) {
        self.downloader = downloader
        self.configurator = configurator
        self.installer = installer
        self.system = system
        self.fileSystem = fileSystem
        self.console = console
    }

    func execute(with context: MacOSCreateInteractorContext) throws {
        let bundle = try MacOSVMBundle(path: prepareBundlePath(context: context))

        switch context.source {
        case .latest:
            console.error("Downloading the latest restore image is not yet supported")
        case let .ipsw(path: path):
            try createVM(bundle: bundle, context: context, restoreImagePath: path)
        }
    }

    // MARK: - Private

    private func createVM(
        bundle: MacOSVMBundle,
        context: MacOSCreateInteractorContext,
        restoreImagePath: String
    ) throws {
        let cancellable = StateCancellable()

        Task { [weak self] in
            guard let self else { return }
            do {
                // Get restore image path
                let restoreImagePath = try prepareRestoreImagePath(path: restoreImagePath)

                // Create VM bundle
                try await configurator.createVM(with: bundle, spec: .init(
                    restoreImagePath: restoreImagePath,
                    diskSize: prepareDiskSize(context: context),
                    configPath: prepareConfigPath(context: context)
                ))

                // Load VM
                let vm = try configurator.loadVM(with: bundle)

                // Install VM image
                try await installer.install(vm: vm, restoreImagePath: restoreImagePath)

                cancellable.cancel()
            } catch {
                console.error(error.localizedDescription)
                cancellable.cancel()
            }
        }
        system.keepAliveWithSIGINTEventHandler(cancellable: cancellable, signalHandler: { exit in
            cancellable.cancel()
            exit(0)
        })
    }

    private func prepareBundlePath(context: MacOSCreateInteractorContext) throws -> AbsolutePath {
        let destinationPath = try fileSystem.absolutePath(from: context.vmPath ?? UUID().uuidString)
        guard destinationPath.extension == MacOSVMBundle.fileExtension else {
            let filename = destinationPath.basename
            return destinationPath.parentDirectory.appending(component: "\(filename).\(MacOSVMBundle.fileExtension)")
        }
        return destinationPath
    }

    private func prepareDiskSize(context: MacOSCreateInteractorContext) throws -> MemorySize {
        guard let diskSize = context.diskSize else {
            return Constants.defaultDiskSize
        }
        guard let diskSize = MemorySize(string: diskSize) else {
            throw CoreError.generic("Invalid disk size '\(diskSize)'")
        }
        return diskSize
    }

    private func prepareConfigPath(context: MacOSCreateInteractorContext) throws -> AbsolutePath? {
        guard let path = context.configPath else {
            return nil
        }
        return try fileSystem.absolutePath(from: path)
    }

    private func prepareRestoreImagePath(path: String) throws -> AbsolutePath {
        try fileSystem.absolutePath(from: path)
    }
}
