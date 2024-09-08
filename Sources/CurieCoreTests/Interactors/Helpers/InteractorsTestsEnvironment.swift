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
import CurieCommonMocks
@testable import CurieCore
import CurieCoreMocks
import Foundation
import SCInject

final class InteractorsTestsEnvironment {
    let restoreImageService = MockRestoreImageService()
    let httpClient = MockHTTPClient()
    let console = MockConsole()
    let runLoop = DefaultRunLoop(interval: .short)

    func resolveInteractor() -> Interactor {
        let systemContainer = DefaultContainer()
        Assembler(container: systemContainer).assemble([
            CommonAssembly(),
            CoreAssembly(),
        ])
        let testContainer = DefaultContainer(parent: systemContainer)
        testContainer.register(RestoreImageService.self) { [restoreImageService] _ in restoreImageService }
        testContainer.register(HTTPClient.self) { [httpClient] _ in httpClient }
        testContainer.register(Console.self) { [console] _ in console }
        testContainer.register(CurieCommon.RunLoop.self) { [runLoop] _ in runLoop }
        return testContainer.resolve(Interactor.self)
    }
}
