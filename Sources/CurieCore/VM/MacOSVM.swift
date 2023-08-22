import CurieCommon
import Foundation
import Virtualization

final class MacOSVM {
    let config: MacOSVMConfig

    private let vm: VZVirtualMachine
    private let console: Console

    init(
        vm: VZVirtualMachine,
        config: MacOSVMConfig,
        console: Console
    ) {
        self.vm = vm
        self.config = config
        self.console = console
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
        vm.stop { error in
            if let error {
                completionHandler(.failure(error))
            } else {
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
}
