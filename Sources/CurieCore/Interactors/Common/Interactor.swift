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

protocol AsyncInteractor: AnyObject {
    associatedtype Context

    func execute(context: Context, runLoop: RunLoopAccessor) async throws
}

final class AsyncInteractorAdapter<Interactor: AsyncInteractor> {
    private let interactor: Interactor
    private let runLoop: CurieCommon.RunLoop

    init(interactor: Interactor, runLoop: CurieCommon.RunLoop) {
        self.interactor = interactor
        self.runLoop = runLoop
    }

    func execute(context: Interactor.Context) throws {
        try runLoop.run { [self] _ in
            try await interactor.execute(context: context, runLoop: runLoop)
        }
    }
}
