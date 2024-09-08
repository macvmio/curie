import CurieCommon
import Foundation
import TSCBasic

public struct BuildInteractorContext {
    var ipwsPath: String
    var reference: String
    var diskSize: String?
    var configPath: String?

    public init(
        ipwsPath: String,
        reference: String,
        diskSize: String?,
        configPath: String?
    ) {
        self.ipwsPath = ipwsPath
        self.reference = reference
        self.diskSize = diskSize
        self.configPath = configPath
    }
}

public protocol BuildInteractor {
    func execute(with context: BuildInteractorContext) throws
}

final class DefaultBuildInteractor: BuildInteractor {
    private let downloader: RestoreImageDownloader
    private let configurator: VMConfigurator
    private let installer: VMInstaller
    private let imageCache: ImageCache
    private let fileSystem: CurieCommon.FileSystem
    private let runloop: ProcessRunloop
    private let console: Console

    init(
        downloader: RestoreImageDownloader,
        configurator: VMConfigurator,
        installer: VMInstaller,
        imageCache: ImageCache,
        fileSystem: CurieCommon.FileSystem,
        runloop: ProcessRunloop,
        console: Console
    ) {
        self.downloader = downloader
        self.configurator = configurator
        self.installer = installer
        self.imageCache = imageCache
        self.fileSystem = fileSystem
        self.runloop = runloop
        self.console = console
    }

    func execute(with context: BuildInteractorContext) throws {
        let reference = try imageCache.makeImageReference(context.reference)
        let bundlePath = try imageCache.path(to: reference)
        let bundle = VMBundle(path: bundlePath)

        try createImage(
            reference: reference,
            bundle: bundle,
            context: context,
            restoreImagePath: context.ipwsPath
        )
    }

    // MARK: - Private

    private func createImage(
        reference: ImageReference,
        bundle: VMBundle,
        context: BuildInteractorContext,
        restoreImagePath: String
    ) throws {
        Task { [weak self] in
            guard let self else { return }
            do {
                // Get restore image path
                let restoreImagePath = try prepareRestoreImagePath(path: restoreImagePath)

                // Create VM bundle
                try await configurator.createVM(with: bundle, spec: .init(
                    reference: reference,
                    restoreImagePath: restoreImagePath,
                    diskSize: prepareDiskSize(context: context),
                    configPath: prepareConfigPath(context: context)
                ))

                // Load VM
                let vm = try configurator.loadVM(with: bundle, overrideConfig: nil)

                // Install VM image
                try await installer.install(vm: vm, restoreImagePath: restoreImagePath)

                runloop.terminate()
            } catch let error as CoreError {
                runloop.error(error)
            } catch {
                runloop.error(.generic(error.localizedDescription))
            }
        }

        try runloop.run()
    }

    private func prepareDiskSize(context: BuildInteractorContext) throws -> MemorySize {
        guard let diskSize = context.diskSize else {
            return Constants.defaultDiskSize
        }
        guard let diskSize = MemorySize(string: diskSize) else {
            throw CoreError.generic("Invalid disk size '\(diskSize)'")
        }
        return diskSize
    }

    private func prepareConfigPath(context: BuildInteractorContext) throws -> AbsolutePath? {
        guard let path = context.configPath else {
            return nil
        }
        return try fileSystem.absolutePath(from: path)
    }

    private func prepareRestoreImagePath(path: String) throws -> AbsolutePath {
        try fileSystem.absolutePath(from: path)
    }
}
