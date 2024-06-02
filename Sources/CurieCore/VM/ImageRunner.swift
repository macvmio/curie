import CurieCommon
import Foundation

protocol ImageRunner {
    func run(vm: VM, bundle: VMBundle, options: VMStartOptions) throws
}

final class DefaultImageRunner: ImageRunner {
    private let windowAppLauncher: MacOSWindowAppLauncher
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let system: System
    private let fileSystem: FileSystem
    private let console: Console

    init(
        windowAppLauncher: MacOSWindowAppLauncher,
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        system: System,
        fileSystem: FileSystem,
        console: Console
    ) {
        self.windowAppLauncher = windowAppLauncher
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.system = system
        self.fileSystem = fileSystem
        self.console = console
    }

    func run(vm: VM, bundle: VMBundle, options: VMStartOptions) throws {
        let info = try VMInfo(
            config: vm.config,
            metadata: bundleParser.readMetadata(from: bundle)
        )
        console.text(info.description)

        if fileSystem.exists(at: bundle.machineState) {
            let deleteMachineStateFile = { [console, fileSystem] in
                do {
                    try fileSystem.remove(at: bundle.machineState)
                } catch {
                    console.error("Failed to delete machine state file of the container. \(error)")
                    exit(1)
                }
            }
            vm.resume(machineStateURL: bundle.machineState.asURL) { [console] result in
                switch result {
                case .success:
                    console.text("Container \(info.metadata.id.description) started")
                    deleteMachineStateFile()
                case let .failure(error):
                    console.error("Failed to start container. \(error)")
                    deleteMachineStateFile()
                    exit(1)
                }
            }
        } else {
            vm.start(options: options) { [console] result in
                switch result {
                case .success:
                    console.text("Container \(info.metadata.id.description) started")
                case let .failure(error):
                    console.error("Failed to start container. \(error)")
                }
            }
        }

        // Launch interface
        if options.noWindow {
            console.text("Launch container without a window")
            launchConsole(with: vm, bundle: bundle)
        } else {
            console.text("Launch container in a window")
            launchWindow(with: vm, bundle: bundle)
        }
    }

    private func launchConsole(with vm: VM, bundle: VMBundle) {
        withExtendedLifetime(vm) { _ in
            system.keepAliveWithSIGINTEventHandler { exit in
                vm.exit(machineStateURL: bundle.machineState.asURL, exit: exit)
            }
        }
    }

    private func launchWindow(with vm: VM, bundle: VMBundle) {
        let sourceSignal = system.SIGINTEventHandler { exit in
            vm.exit(machineStateURL: bundle.machineState.asURL, exit: exit)
        }
        vm.addSourceSignal(sourceSignal)

        windowAppLauncher.launchWindow(with: vm, bundle: bundle)
    }
}
