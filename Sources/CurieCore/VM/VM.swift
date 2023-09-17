import Combine
import CurieCommon
import Foundation
import Virtualization

final class VM: NSObject {
    enum Event: Equatable {
        case imageDidStop
        case imageStopFailed
    }

    public var events: AnyPublisher<Event, Never> {
        _events.eraseToAnyPublisher()
    }

    let config: VMConfig

    private let vm: VZVirtualMachine
    private let console: Console
    private let _events = PassthroughSubject<Event, Never>()

    private var sourceSignals: [DispatchSourceSignal] = []

    init(
        vm: VZVirtualMachine,
        config: VMConfig,
        console: Console
    ) {
        self.vm = vm
        self.config = config
        self.console = console

        super.init()

        vm.delegate = self
    }

    public func start(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will start VM")
        vm.start(completionHandler: completionHandler)
    }

    public func pause(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will pause VM")
        vm.pause(completionHandler: completionHandler)
    }

    public func resume(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        console.text("Will resume VM")
        vm.resume(completionHandler: completionHandler)
    }

    public func stop(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        guard vm.state != .stopped else {
            completionHandler(.success(()))
            return
        }

        console.text("Will stop VM")
        // swiftlint:disable:next identifier_name
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

    public func exit(exit: @escaping (Int32) -> Never) {
        console.text("Will exit VM")
        stop { [console] result in
            switch result {
            case .success:
                console.text("Stopped the VM")
                exit(0)
            case let .failure(error):
                console.error("Failed to stop the VM, \(error)")
                exit(1)
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
        console.error("VM stopped with error. \(error)")
        _events.send(.imageStopFailed)
        Darwin.exit(1)
    }

    func guestDidStop(_: VZVirtualMachine) {
        console.text("Guest did stop VM")
        _events.send(.imageDidStop)
        Darwin.exit(0)
    }
}
