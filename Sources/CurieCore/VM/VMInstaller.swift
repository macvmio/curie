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

    init(console: Console) {
        self.console = console
    }

    func install(vm: VM, restoreImagePath: AbsolutePath) async throws {
        let installer = VZMacOSInstaller(
            virtualMachine: vm.virtualMachine,
            restoringFromImageAt: restoreImagePath.asURL
        )
        let observer: NSKeyValueObservation = installer.progress.observe(
            \.fractionCompleted,
            options: [.initial, .new]
        ) { [console] _, change in
            console.progress(prompt: "Building", progress: change.newValue ?? 0)
        }
        let result = await withCheckedContinuation { continuation in
            queue.async { [console] in
                installer.install { result in
                    console.clear()
                    continuation.resume(returning: result)
                }
            }
        }
        withExtendedLifetime(observer) {}

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
