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

public struct StartInteractorContext {
    public var reference: String
    public var launch: LaunchParameters

    public init(reference: String, launch: LaunchParameters) {
        self.reference = reference
        self.launch = launch
    }
}

public protocol StartInteractor {
    func execute(with context: StartInteractorContext) throws
}

public final class DefaultStartInteractor: StartInteractor {
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

    public func execute(with context: StartInteractorContext) throws {
        console.text("Start \(context.reference) container")

        let sourceReference = try imageCache.findContainerReference(context.reference)

        let bundle = try imageCache.bundle(for: sourceReference)
        let overrideConfig = try context.launch.partialConfig()
        let vm = try configurator.loadVM(with: bundle, overrideConfig: overrideConfig)
        let options = VMStartOptions(
            startUpFromMacOSRecovery: context.launch.recoveryMode,
            showWindow: context.launch.showWindow,
            socketPath: context.launch.socketPath
        )

        try imageRunner.run(vm: vm, bundle: bundle, options: options)
    }
}
