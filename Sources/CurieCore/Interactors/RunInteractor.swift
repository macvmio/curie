import CurieCommon
import Foundation
import TSCBasic
import Virtualization

public struct RunInteractorContext {
    public var reference: String
    public var noWindow: Bool

    public init(
        reference: String,
        noWindow: Bool
    ) {
        self.reference = reference
        self.noWindow = noWindow
    }
}

public protocol RunInteractor {
    func execute(with context: RunInteractorContext) throws
}

public final class DefaultRunInteractor: RunInteractor {
    private let configurator: VMConfigurator
    private let windowAppLauncher: MacOSWindowAppLauncher
    private let imageCache: ImageCache
    private let system: System
    private let console: Console

    init(
        configurator: VMConfigurator,
        windowAppLauncher: MacOSWindowAppLauncher,
        imageCache: ImageCache,
        system: System,
        console: Console
    ) {
        self.configurator = configurator
        self.windowAppLauncher = windowAppLauncher
        self.imageCache = imageCache
        self.system = system
        self.console = console
    }

    public func execute(with context: RunInteractorContext) throws {
        console.text("Run image \(context.reference)")

        let reference = try imageCache.findReference(context.reference)

        let bundle = VMBundle(path: imageCache.path(to: reference))
        let vm = try configurator.loadVM(with: bundle)

        console.text(vm.config.asString())

        // Automatically start the vm
        vm.start(completionHandler: { [console] result in
            switch result {
            case .success:
                console.text("The VM started")
            case let .failure(error):
                console.error("Failed to start the VM. \(error)")
            }
        })

        // Launch interface
        if context.noWindow {
            console.text("Launch the VM without a window")
            launchConsole(with: vm)
        } else {
            console.text("Launch the VM in a window")
            launchWindow(with: vm)
        }
    }

    private func launchConsole(with vm: VM) {
        withExtendedLifetime(vm) { _ in
            system.keepAliveWithSIGINTEventHandler { exit in
                vm.exit(exit: exit)
            }
        }
    }

    private func launchWindow(with vm: VM) {
        windowAppLauncher.launchWindow(with: vm)
    }
}
