import CurieCommon
import Foundation
import Virtualization

final class VirtualMachineDelegate: NSObject, VZVirtualMachineDelegate {
    private let console: Console

    init(console: Console) {
        self.console = console
    }
}
