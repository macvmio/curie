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

import CurieCommon
import Dispatch
import Foundation

final class TerminateVmRequestProcessor {
    init() {}

    func process(
        request: TerminateVmPayload,
        vm: VM,
        vmBundle: VMBundle,
        socketQueue: DispatchQueue
    ) -> PromisedSocketResponse {
        let timeout = request.waitToComplete ? request.timeout : 0

        // VM is being terminated, so current process will die
        // We should close the socket nicely before teminating the current process, so clients don't get weird
        // connection errors
        let closeSocketAfterDeliveringResponse = true
        let settableResponse = BlockingSocketResponse(
            timeout: timeout,
            closeSocketAfterDeliveringResponse: closeSocketAfterDeliveringResponse
        )

        DispatchQueue.main.async {
            vm.terminateVmAndCurrentProcess(machineStateURL: vmBundle.machineState.asURL) { terminationResult in
                switch terminationResult {
                case .success:
                    settableResponse.set(response: .success([:]))
                case let .failure(error):
                    settableResponse.set(response: .error("Failed to terminate VM: \(error)"))
                }

                socketQueue.sync(flags: .barrier) {}
            }
        }

        if request.waitToComplete {
            return settableResponse
        }

        return ConstantPromisedSocketResponse(
            response: .success([:]),
            closeSocketAfterDeliveringResponse: closeSocketAfterDeliveringResponse
        )
    }
}
