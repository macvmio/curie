import CurieCommon
import Foundation

// swiftlint:disable function_body_length
public final class CoreAssembly: Assembly {
    public init() {}

    public func assemble(_ registry: Registry) {
        assembleInteractors(registry)
        assembleUtils(registry)
    }

    // MARK: - Private

    private func assembleInteractors(_ registry: Registry) {
        registry.register(RunInteractor.self) { r in
            DefaultRunInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageRunner: r.resolve(ImageRunner.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(StartInteractor.self) { r in
            DefaultStartInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageRunner: r.resolve(ImageRunner.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(BuildInteractor.self) { r in
            DefaultBuildInteractor(
                downloader: r.resolve(RestoreImageDownloader.self),
                configurator: r.resolve(VMConfigurator.self),
                installer: r.resolve(VMInstaller.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImagesInteractor.self) { r in
            DefaultImagesInteractor(
                imageCache: r.resolve(ImageCache.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(RmInteractor.self) { r in
            DefaultRmInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(RmiInteractor.self) { r in
            DefaultRmiInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CloneInteractor.self) { r in
            DefaultCloneInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(InspectInteractor.self) { r in
            DefaultInspectInteractor(
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                aprClient: r.resolve(ARPClient.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CreateInteractor.self) { r in
            DefaultCreateInteractor(
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CommitInteractor.self) { r in
            DefaultCommitInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(PsInteractor.self) { r in
            DefaultPsInteractor(
                imageCache: r.resolve(ImageCache.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(DownloadInteractor.self) { r in
            DefaultDownloadInteractor(
                downloader: r.resolve(RestoreImageDownloader.self),
                fileSystem: r.resolve(FileSystem.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ExportInteractor.self) { r in
            DefaultExportInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImportInteractor.self) { r in
            DefaultImportInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ConfigInteractor.self) { r in
            DefaultConfigInteractor(
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                system: r.resolve(System.self)
            )
        }
    }

    private func assembleUtils(_ registry: Registry) {
        registry.register(VMBundleParser.self) { r in
            DefaultVMBundleParser(
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(VMConfigurator.self) { r in
            DefaultVMConfigurator(
                bundleParser: r.resolve(VMBundleParser.self),
                fileSystem: r.resolve(FileSystem.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSWindowAppLauncher.self) { _ in
            MacOSWindowAppLauncher()
        }
        registry.register(RestoreImageDownloader.self) { r in
            DefaultRestoreImageDownloader(
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(VMInstaller.self) { r in
            DefaultVMInstaller(
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImageCache.self) { r in
            DefaultImageCache(
                bundleParser: r.resolve(VMBundleParser.self),
                wallClock: r.resolve(WallClock.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(ImageRunner.self) { r in
            DefaultImageRunner(
                windowAppLauncher: r.resolve(MacOSWindowAppLauncher.self),
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(WallClock.self) { _ in
            DefaultWallClock()
        }
        registry.register(ARPClient.self) { r in
            DefaultARPClient(
                system: r.resolve(System.self)
            )
        }
    }
}

// swiftlint:enable function_body_length
