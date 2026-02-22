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

final class SynthesizeMouseInputProcessor {
    init() {}

    func process(request: SynthesizeMousePayload) -> PromisedSocketResponse {
        let response = BlockingSocketResponse(
            timeout: request.timeout,
            closeSocketAfterDeliveringResponse: false
        )

        DispatchQueue.main.async {
            do {
                let targetWindow = try NSApp.getSingleVmWindow()
                try targetWindow.synthesize(
                    mouseClicks: request.mouseClicks,
                    callbackQueue: .main
                ) {
                    response.set(response: .success([:]))
                }
            } catch {
                response.set(response: .error("Failed to synthesize mouse input: \(error)"))
            }
        }

        return response
    }
}
