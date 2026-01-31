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

import Combine
import CurieCommon
import Foundation

protocol ImageRunner {
    func run(vm: VM, bundle: VMBundle, options: VMStartOptions) throws
}

final class DefaultImageRunner: ImageRunner {
    private let windowAppLauncher: MacOSWindowAppLauncher
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let clipboardSyncService: ClipboardSyncService
    private let system: System
    private let fileSystem: FileSystem
    private let console: Console
    private let vmSocketServer: VMSocketServer
    private var cancellables = Set<AnyCancellable>()

    init(
        windowAppLauncher: MacOSWindowAppLauncher,
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        clipboardSyncService: ClipboardSyncService,
        system: System,
        fileSystem: FileSystem,
        console: Console,
        vmSocketServer: VMSocketServer
    ) {
        self.windowAppLauncher = windowAppLauncher
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.clipboardSyncService = clipboardSyncService
        self.system = system
        self.fileSystem = fileSystem
        self.console = console
        self.vmSocketServer = vmSocketServer
    }

    func run(vm: VM, bundle: VMBundle, options: VMStartOptions) throws {
        let info = try VMInfo(
            config: vm.config,
            metadata: bundleParser.readMetadata(from: bundle)
        )
        console.text(info.description)

        try startSocketServerIfNeeded(vm: vm, bundle: bundle, options: options)

        if fileSystem.exists(at: bundle.machineState) {
            let deleteMachineStateFile = { [console, fileSystem] in
                do {
                    try fileSystem.remove(at: bundle.machineState)
                } catch {
                    console.error("Failed to delete machine state file of the container. \(error)")
                    exit(1)
                }
            }
            vm.resume(machineStateURL: bundle.machineState.asURL) { [console, clipboardSyncService] result in
                switch result {
                case .success:
                    console.text("Container \(info.metadata.id.description) started")
                    deleteMachineStateFile()
                    vm.startClipboardSync(service: clipboardSyncService)
                case let .failure(error):
                    console.error("Failed to start container. \(error)")
                    deleteMachineStateFile()
                    exit(1)
                }
            }
        } else {
            vm.start(options: options) { [console, clipboardSyncService] result in
                switch result {
                case .success:
                    if console.quiet {
                        console.text(info.metadata.id.description, always: true)
                    } else {
                        console.text("Container \(info.metadata.id.description) started")
                    }
                    vm.startClipboardSync(service: clipboardSyncService)
                case let .failure(error):
                    console.error("Failed to start container. \(error)")
                }
            }
        }

        // Launch interface
        if options.showWindow {
            console.text("Launch container in a window")
            launchWindow(with: vm, bundle: bundle)
        } else {
            console.text("Launch container without a window")
            launchConsole(with: vm, bundle: bundle)
        }
    }

    private func startSocketServerIfNeeded(
        vm: VM,
        bundle: VMBundle,
        options: VMStartOptions
    ) throws {
        guard let socketPath = options.unixSocketPath else { return }
        do {
            try vmSocketServer.startServer(
                socketPath: socketPath,
                vm: vm,
                vmBundle: bundle,
                windowAppLauncher: windowAppLauncher
            )
            console.text("Started socket server at \(socketPath)")
            scheduleSocketServerStop(vm: vm, options: options)
        } catch {
            console.error("Failed to start socket server: \(error)")
            throw error
        }
    }

    private func scheduleSocketServerStop(
        vm: VM,
        options _: VMStartOptions
    ) {
        vm.events
            .filter { $0 == .imageDidStop || $0 == .imageStopFailed }
            .sink { [vmSocketServer, console] _ in
                do {
                    try vmSocketServer.stop()
                    console.text("Stopped socket server")
                } catch {
                    console.error("Failed to close socket server: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    private func launchConsole(with vm: VM, bundle: VMBundle) {
        withExtendedLifetime(vm) { _ in
            system.keepAlive {
                vm.terminateVmAndCurrentProcess(
                    machineStateURL: bundle.machineState.asURL
                )
            }
        }
    }

    private func launchWindow(with vm: VM, bundle: VMBundle) {
        let sigint = system.makeSIGINTSourceSignal {
            vm.terminateVmAndCurrentProcess(
                machineStateURL: bundle.machineState.asURL
            )
        }
        vm.addSourceSignal(sigint)

        let sigterm = system.makeSIGTERMSourceSignal {
            vm.terminateVmAndCurrentProcess(
                machineStateURL: bundle.machineState.asURL
            )
        }
        vm.addSourceSignal(sigterm)

        windowAppLauncher.launchWindow(with: vm, bundle: bundle)
    }
}
