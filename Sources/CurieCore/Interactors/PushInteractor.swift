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

public struct PushParameters {
    public let reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

final class PushInteractor: AsyncInteractor {
    private let pluginExecutor: PluginExecutor
    private let console: Console

    init(
        pluginExecutor: PluginExecutor,
        console: Console
    ) {
        self.pluginExecutor = pluginExecutor
        self.console = console
    }

    func execute(parameters: PushParameters) async throws {
        try pluginExecutor.executePlugin(.push, parameters: ["reference": parameters.reference])
    }
}
