import CurieCommon
import Foundation
import Virtualization

final class MacOSVirtualMachineDelegate: NSObject, VZVirtualMachineDelegate {
    private let console: Console

    init(console: Console) {
        self.console = console
    }

    func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
        console.error("VM stopped with error. \(error)")
        exit(1)
    }

    func guestDidStop(_: VZVirtualMachine) {
        console.text("Guest did stop VM")
        exit(0)
    }
}
