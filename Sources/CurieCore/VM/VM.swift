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
    var noWindow: Bool
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

    func start(options: VMStartOptions) async throws {
        let startOptions = VZMacOSVirtualMachineStartOptions()
        startOptions.startUpFromMacOSRecovery = options.startUpFromMacOSRecovery
        try await vm.start() // TODO: Map the error "Failed to start container."
    }

//
//    func start(options: VMStartOptions, completionHandler: @escaping (Result<Void, Error>) -> Void) {
//        console.text("Will start container")
//        let startOptions = VZMacOSVirtualMachineStartOptions()
//        startOptions.startUpFromMacOSRecovery = options.startUpFromMacOSRecovery
//        vm.start(options: startOptions) { error in
//            if let error {
//                completionHandler(.failure(error))
//            } else {
//                completionHandler(.success(()))
//            }
//        }
//    }
//
    func pause(machineStateURL: URL) async throws {
        console.text("Will pause container")
        try await vm.pause()
        if #available(macOS 14.0, *) {
            try await vm.saveMachineStateTo(url: machineStateURL)
        }
    }

//    func pause(machineStateURL: URL, completionHandler: @escaping (Result<Void, Error>) -> Void) {
//        console.text("Will pause container")
//        vm.pause { [vm] result in
//            switch result {
//            case .success:
//                if #available(macOS 14.0, *) {
//                    vm.saveMachineStateTo(url: machineStateURL) { error in
//                        if let error {
//                            completionHandler(.failure(error))
//                        } else {
//                            completionHandler(.success(()))
//                        }
//                    }
//                } else {
//                    completionHandler(.success(()))
//                }
//            case let .failure(error):
//                completionHandler(.failure(error))
//            }
//        }
//    }

    func resume(machineStateURL: URL) async throws {
        console.text("Will start paused container")
        if #available(macOS 14.0, *) {
            try await vm.restoreMachineStateFrom(url: machineStateURL)
        } else {
            throw CoreError.generic("Failed to resume paused container, unsupported OS")
        }
    }

//
//    func resume(machineStateURL: URL, completionHandler: @escaping (Result<Void, Error>) -> Void) {
//        console.text("Will start paused container")
//        if #available(macOS 14.0, *) {
//            vm.restoreMachineStateFrom(url: machineStateURL) { [vm] error in
//                if let error {
//                    completionHandler(.failure(error))
//                } else {
//                    vm.resume(completionHandler: completionHandler)
//                }
//            }
//        } else {
//            completionHandler(.failure(CoreError.generic("TODO - FIXME")))
//        }
//    }

    func stop() async throws {
        guard vm.state != .stopped else {
            return
        }

        console.text("Will stop container")
        do {
            try await vm.stop()
            _events.send(.imageDidStop)
        } catch {
            _events.send(.imageStopFailed)
            throw error
        }
    }

//
//    func stop(completionHandler: @escaping (Result<Void, Error>) -> Void) {
//        guard vm.state != .stopped else {
//            completionHandler(.success(()))
//            return
//        }
//
//        console.text("Will stop container")
//        // swiftlint:disable:next identifier_name
//        vm.stop { [_events] error in
//            if let error {
//                _events.send(.imageStopFailed)
//                completionHandler(.failure(error))
//            } else {
//                _events.send(.imageDidStop)
//                completionHandler(.success(()))
//            }
//        }
//    }

    func exit(machineStateURL: URL) async throws {
        do {
            switch config.shutdown.behaviour {
            case .stop:
                try await stop()
            case .pause:
                try await pause(machineStateURL: machineStateURL)
            }
            console.text("Did \(config.shutdown.behaviour.description) container")
        } catch {
            throw CoreError(
                message: "Failed to \(config.shutdown.behaviour.description) container",
                metadata: ["ERROR": "\(error)"]
            )
        }
    }

//    func exit(machineStateURL: URL, exit: @escaping (Int32) -> Never) {
//        console.text("Will exit container")
//        let completion = { [console, config] (result: Result<Void, Error>) in
//            switch result {
//            case .success:
//                console.text("Did \(config.shutdown.behaviour.description) container")
//                exit(0)
//            case let .failure(error):
//                console.error("Failed to \(config.shutdown.behaviour.description) container, \(error)")
//                exit(1)
//            }
//        }
//    }

    var virtualMachine: VZVirtualMachine {
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
