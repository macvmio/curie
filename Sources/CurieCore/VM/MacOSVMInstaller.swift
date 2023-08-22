import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol MacOSVMInstaller {
    func install(vm: MacOSVM, restoreImagePath: AbsolutePath) async throws
}

@MainActor
final class DefaultMacOSVMInstaller: MacOSVMInstaller {
    private let console: Console
    private var observer: NSKeyValueObservation?

    nonisolated init(
        console: Console
    ) {
        self.console = console
    }

    func install(vm: MacOSVM, restoreImagePath: AbsolutePath) async throws {
        console.text("Install VM image")

        let installer = VZMacOSInstaller(
            virtualMachine: vm.virtualMachine,
            restoringFromImageAt: restoreImagePath.asURL
        )

        observer = installer.progress.observe(
            \.fractionCompleted,
            options: [.initial, .new]
        ) { [console] _, change in
            console.text("Installing... \(Int(change.newValue! * 100))%")
        }

        let result = await withCheckedContinuation { continuation in
            installer.install { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            console.text("Installed VM image")
            return
        case let .failure(error):
            throw CoreError
                .generic("Failed to install macOS from restore image at path '\(restoreImagePath)'. \(error)")
        }
    }
}
