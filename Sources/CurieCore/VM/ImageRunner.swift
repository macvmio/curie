import CurieCommon
import Foundation

protocol ImageRunner {
    func run(vm: VM, bundle: VMBundle, noWindow: Bool) throws
}

final class DefaultImageRunner: ImageRunner {
    private let windowAppLauncher: MacOSWindowAppLauncher
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let system: System
    private let console: Console

    init(
        windowAppLauncher: MacOSWindowAppLauncher,
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        system: System,
        console: Console
    ) {
        self.windowAppLauncher = windowAppLauncher
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.system = system
        self.console = console
    }

    func run(vm: VM, bundle: VMBundle, noWindow: Bool) throws {
        let info = try bundleParser.readInfo(from: bundle)
        console.text(info.description)

        // Automatically start the vm
        vm.start(completionHandler: { [console] result in
            switch result {
            case .success:
                console.text("Container \(info.state.id.description) started")
            case let .failure(error):
                console.error("Failed to start container. \(error)")
            }
        })

        // Launch interface
        if noWindow {
            console.text("Launch container without a window")
            launchConsole(with: vm)
        } else {
            console.text("Launch container in a window")
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
        let sourceSignal = system.SIGINTEventHandler { exit in
            vm.exit(exit: exit)
        }
        vm.addSourceSignal(sourceSignal)

        windowAppLauncher.launchWindow(with: vm)
    }
}
