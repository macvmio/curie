import CurieCommon
import Foundation

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
                windowAppLauncher: r.resolve(MacOSWindowAppLauncher.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CreateInteractor.self) { r in
            DefaultCreateInteractor(
                downloader: r.resolve(RestoreImageDownloader.self),
                configurator: r.resolve(VMConfigurator.self),
                installer: r.resolve(VMInstaller.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(RemoveInteractor.self) { r in
            DefaultRemoveInteractor(
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
                virtualMachineDelegate: r.resolve(VirtualMachineDelegate.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSWindowAppLauncher.self) { _ in
            MacOSWindowAppLauncher()
        }
        registry.register(RestoreImageDownloader.self) { r in
            DefaultRestoreImageDownloader(
                console: r.resolve(Console.self)
            )
        }
        registry.register(VMInstaller.self) { r in
            DefaultVMInstaller(
                console: r.resolve(Console.self)
            )
        }
        registry.register(VirtualMachineDelegate.self) { r in
            VirtualMachineDelegate(
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImageCache.self) { r in
            DefaultImageCache(
                bundleParser: r.resolve(VMBundleParser.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self)
            )
        }
    }
}
