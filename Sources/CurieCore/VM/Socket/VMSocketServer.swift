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
import Dispatch
import Foundation

protocol VMSocketServer {
    func startServer(
        socketPath: String,
        vm: VM,
        vmBundle: VMBundle
    ) throws

    func stop() throws
}

final class VMSocketServerImpl: VMSocketServer {
    private let lock = NSLock()
    private let socketQueue: DispatchQueue
    private let unixSocketServer = UnixDomainSocketServer()

    init(
        socketQueue: DispatchQueue
    ) {
        self.socketQueue = socketQueue
    }

    func startServer(
        socketPath: String,
        vm: VM,
        vmBundle: VMBundle
    ) throws {
        try lock.withLock {
            _ = try unixSocketServer.start(
                socketPath: socketPath,
                responseProvider: { [weak self] (request: CurieSocketRequest) in
                    guard let self else {
                        return Response(
                            payload: CurieSocketResponse.error("Internal error: server instance has been deallocated"),
                            closeSocketAfterDeliveringResponse: true
                        )
                    }
                    return createResponse(
                        request: request,
                        vm: vm,
                        vmBundle: vmBundle
                    )
                },
                connectionQueue: socketQueue
            )
        }
    }

    func stop() throws {
        try lock.withLock {
            try unixSocketServer.close()
        }
    }

    private func createResponse(
        request: CurieSocketRequest,
        vm: VM,
        vmBundle: VMBundle
    ) -> Response<CurieSocketResponse> {
        let promisedResponse: PromisedSocketResponse

        switch request {
        case let .ping(pingRequest):
            let processor = PingRequestProcessor()
            promisedResponse = processor.process(request: pingRequest)

        case let .terminateVm(terminateVmPayload):
            let processor = TerminateVmRequestProcessor()
            promisedResponse = processor.process(
                request: terminateVmPayload,
                vm: vm,
                vmBundle: vmBundle,
                socketQueue: socketQueue
            )

        case let .makeScreenshot(makeScreenshotPayload):
            let processor = MakeScreenshotRequestProcessor(
                vmScreenshotter: VMScreenshotterImpl()
            )
            promisedResponse = processor.process(request: makeScreenshotPayload)
        }

        let socketResponse: CurieSocketResponse = promisedResponse.getSocketResponse()
        return Response(
            payload: socketResponse,
            closeSocketAfterDeliveringResponse: promisedResponse
                .closeSocketAfterDeliveringResponse
        )
    }
}
