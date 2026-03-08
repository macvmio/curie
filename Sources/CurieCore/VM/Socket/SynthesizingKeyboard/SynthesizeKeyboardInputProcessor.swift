//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
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

import AppKit
import CurieCommon
import Foundation

final class SynthesizeKeyboardInputProcessor {
    init() {}

    func process(request: SynthesizeKeyboardPayload) -> PromisedSocketResponse {
        let response = BlockingSocketResponse(
            timeout: request.timeout,
            closeSocketAfterDeliveringResponse: false
        )
        nonisolated(unsafe) let unsafeResponse = response

        DispatchQueue.main.async {
            do {
                let targetWindow = try NSApp.getSingleVmWindow()
                try targetWindow.synthesize(keyboardInput: request.input, callbackQueue: .main) {
                    unsafeResponse.set(response: .success([:]))
                }
            } catch {
                unsafeResponse.set(response: .error("Failed to synthesize keyboard input: \(error)"))
            }
        }

        return response
    }
}
