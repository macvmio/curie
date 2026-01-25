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
import Virtualization

struct VMStartOptions {
    var startUpFromMacOSRecovery: Bool
    var showWindow: Bool
}

final class VM: NSObject {
    enum Event: Equatable {
        case imageDidStop
        case imageStopFailed
    }

    public var events: AnyPublisher<Event, Never> {
        _events.eraseToAnyPublisher()
    }

    let config: VMConfig
    let metadata: VMMetadata

    private let vm: VZVirtualMachine
    private let console: Console
    private let _events = PassthroughSubject<Event, Never>()

    private var sourceSignals: [DispatchSourceSignal] = []
    private var clipboardSyncService: ClipboardSyncService?

    init(
        vm: VZVirtualMachine,
        config: VMConfig,
        metadata: VMMetadata,
        console: Console
    ) {
        self.vm = vm
        self.config = config
        self.metadata = metadata
        self.console = console

        super.init()

        vm.delegate = self
    }

    public func startClipboardSync(service: ClipboardSyncService) {
        guard config.clipboard.enabled else {
            return
        }
        guard let socketDevice = vm.socketDevices.first as? VZVirtioSocketDevice else {
            console.text("No socket device available for clipboard sync")
            return
        }
        clipboardSyncService = service
        service.start(socketDevice: socketDevice)
    }

    public func stopClipboardSync() {
        clipboardSyncService?.stop()
        clipboardSyncService = nil
    }

    public func start(options: VMStartOptions, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will start container")
        let startOptions = VZMacOSVirtualMachineStartOptions()
        startOptions.startUpFromMacOSRecovery = options.startUpFromMacOSRecovery
        vm.start(options: startOptions) { error in
            if let error {
                completionHandler(.failure(error))
            } else {
                completionHandler(.success(()))
            }
        }
    }

    public func pause(machineStateURL: URL, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will pause container")
        vm.pause { [vm] result in
            switch result {
            case .success:
                if #available(macOS 14.0, *) {
                    vm.saveMachineStateTo(url: machineStateURL) { error in
                        if let error {
                            completionHandler(.failure(error))
                        } else {
                            completionHandler(.success(()))
                        }
                    }
                } else {
                    completionHandler(.success(()))
                }
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    public func resume(machineStateURL: URL, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will start paused container")
        if #available(macOS 14.0, *) {
            vm.restoreMachineStateFrom(url: machineStateURL) { [vm] error in
                if let error {
                    completionHandler(.failure(error))
                } else {
                    vm.resume(completionHandler: completionHandler)
                }
            }
        } else {
            completionHandler(.failure(CoreError.generic("TODO - FIXME")))
        }
    }

    public func stop(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        guard vm.state != .stopped else {
            completionHandler(.success(()))
            return
        }

        console.text("Will stop container")
        vm.stop { [_events] error in
            if let error {
                _events.send(.imageStopFailed)
                completionHandler(.failure(error))
            } else {
                _events.send(.imageDidStop)
                completionHandler(.success(()))
            }
        }
    }

    public func terminate(
        machineStateURL: URL,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        console.text("Will exit container")
        let completion = { [console, config] (result: Result<Void, Error>) in
            switch result {
            case .success:
                console.text("Did \(config.shutdown.behaviour.description) container")
            case let .failure(error):
                console.error("Failed to \(config.shutdown.behaviour.description) container, \(error)")
            }
            completionHandler(result)
        }
        switch config.shutdown.behaviour {
        case .stop:
            stop(completionHandler: completion)
        case .pause:
            pause(machineStateURL: machineStateURL, completionHandler: completion)
        }
    }

    /// Terminates the VM (by stopping or pausing) and then exits the current process.
    /// Exit code is 0 when VM is terminated successfully, and non zero in case of failure.
    public func terminateVmAndCurrentProcess(
        machineStateURL: URL
    ) {
        if vm.state == .stopping { return }
        terminate(machineStateURL: machineStateURL) { vmTerminationResult in
            switch vmTerminationResult {
            case .success:
                Darwin.exit(0)
            case .failure:
                Darwin.exit(1)
            }
        }
    }

    public var virtualMachine: VZVirtualMachine {
        vm
    }

    func addSourceSignal(_ sourceSignal: DispatchSourceSignal) {
        sourceSignals.append(sourceSignal)
    }
}

extension VM: VZVirtualMachineDelegate {
    func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
        console.error("Container stopped with error. \(error)")
        _events.send(.imageStopFailed)
        Darwin.exit(1)
    }

    func guestDidStop(_: VZVirtualMachine) {
        console.text("Guest did stop container")
        _events.send(.imageDidStop)
        Darwin.exit(0)
    }
}
