import CurieCommon
import Foundation
import TSCBasic
import Virtualization

protocol VMInstaller {
    func install(vm: VM, restoreImagePath: AbsolutePath) async throws
}

final class DefaultVMInstaller: VMInstaller {
    private let console: Console
    private let queue: DispatchQueue = .main
    private var observer: NSKeyValueObservation?

    init(console: Console) {
        self.console = console
    }

    func install(vm: VM, restoreImagePath: AbsolutePath) async throws {
        let result = await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self else { return }
                let installer = VZMacOSInstaller(
                    virtualMachine: vm.virtualMachine,
                    restoringFromImageAt: restoreImagePath.asURL
                )

                observer = installer.progress.observe(
                    \.fractionCompleted,
                    options: [.initial, .new]
                ) { [console] _, change in
                    console.progress(prompt: "Building", progress: change.newValue ?? 0)
                }

                installer.install { [console] result in
                    console.clear()
                    continuation.resume(returning: result)
                }
            }
        }

        switch result {
        case .success:
            console.text("Build completed")
            return
        case let .failure(error):
            throw CoreError
                .generic("Failed to install macOS from restore image at path '\(restoreImagePath)'. \(error)")
        }
    }
}
