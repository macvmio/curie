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
import TSCBasic
import Virtualization

public struct RunInteractorContext {
    public var reference: String
    public var launch: LaunchParameters

    public init(reference: String, launch: LaunchParameters) {
        self.reference = reference
        self.launch = launch
    }
}

public protocol RunInteractor {
    func execute(with context: RunInteractorContext) throws
}

public final class DefaultRunInteractor: RunInteractor {
    private let configurator: VMConfigurator
    private let imageRunner: ImageRunner
    private let imageCache: ImageCache
    private let system: System
    private let console: Console

    private var cancellables = Set<AnyCancellable>()

    init(
        configurator: VMConfigurator,
        imageRunner: ImageRunner,
        imageCache: ImageCache,
        system: System,
        console: Console
    ) {
        self.configurator = configurator
        self.imageRunner = imageRunner
        self.imageCache = imageCache
        self.system = system
        self.console = console
    }

    public func execute(with context: RunInteractorContext) throws {
        console.text("Run image \(context.reference)")

        let sourceReference = try imageCache.findImageReference(context.reference)
        let targetReference = try imageCache.cloneImage(source: sourceReference, target: .newReference)

        let bundle = try imageCache.bundle(for: targetReference)
        let overrideConfig = try context.launch.partialConfig()
        let vm = try configurator.loadVM(with: bundle, overrideConfig: overrideConfig)
        let options = VMStartOptions(
            startUpFromMacOSRecovery: context.launch.recoveryMode,
            showWindow: context.launch.showWindow,
            socketPath: context.launch.socketPath
        )

        vm.events
            .filter { $0 == .imageDidStop || $0 == .imageStopFailed }
            .sink { [imageCache, console] _ in
                do {
                    try imageCache.removeImage(targetReference)
                } catch {
                    console.error(error.localizedDescription)
                }
            }
            .store(in: &cancellables)

        try imageRunner.run(vm: vm, bundle: bundle, options: options)
    }
}
