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

public struct StartParameters {
    public var reference: String
    public var launch: LaunchParameters

    public init(reference: String, launch: LaunchParameters) {
        self.reference = reference
        self.launch = launch
    }
}

final class StartInteractor: AsyncInteractor {
    private let configurator: VMConfigurator
    private let imageRunner: ImageRunner
    private let imageCache: ImageCache
    private let system: System
    private let console: Console

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

    func execute(parameters: StartParameters) async throws {
        console.text("Start \(parameters.reference) container")

        let sourceReference = try imageCache.findContainerReference(parameters.reference)

        let bundle = imageCache.bundle(for: sourceReference)
        let overrideConfig = try parameters.launch.partialConfig()
        let vm = try configurator.loadVM(with: bundle, overrideConfig: overrideConfig)
        let options = VMStartOptions(
            startUpFromMacOSRecovery: parameters.launch.recoveryMode,
            noWindow: parameters.launch.noWindow
        )

        try await imageRunner.run(vm: vm, bundle: bundle, options: options)
    }
}
