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
        registry.register(MacOSRunInteractor.self) { r in
            DefaultMacOSRunInteractor(
                configurator: r.resolve(MacOSVMConfigurator.self),
                windowAppLauncher: r.resolve(MacOSWindowAppLauncher.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSCreateInteractor.self) { r in
            DefaultMacOSCreateInteractor(
                downloader: r.resolve(MacOSRestoreImageDownloader.self),
                configurator: r.resolve(MacOSVMConfigurator.self),
                installer: r.resolve(MacOSVMInstaller.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
    }

    private func assembleUtils(_ registry: Registry) {
        registry.register(MacOSVMBundleParser.self) { r in
            DefaultMacOSVMBundleParser(
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(MacOSVMConfigurator.self) { r in
            DefaultMacOSMVConfigurator(
                bundleParser: r.resolve(MacOSVMBundleParser.self),
                fileSystem: r.resolve(FileSystem.self),
                virtualMachineDelegate: r.resolve(MacOSVirtualMachineDelegate.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSWindowAppLauncher.self) { _ in
            MacOSWindowAppLauncher()
        }
        registry.register(MacOSRestoreImageDownloader.self) { r in
            DefaultMacOSRestoreImageDownloader(
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSVMInstaller.self) { r in
            DefaultMacOSVMInstaller(
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSVirtualMachineDelegate.self) { r in
            MacOSVirtualMachineDelegate(
                console: r.resolve(Console.self)
            )
        }
    }
}
