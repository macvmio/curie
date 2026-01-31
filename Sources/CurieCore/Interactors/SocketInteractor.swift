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
import Foundation

public struct SocketInteractorContext {
    public let socketPath: String
    public let socketRequest: CurieSocketRequest

    public init(socketPath: String, socketRequest: CurieSocketRequest) {
        self.socketPath = socketPath
        self.socketRequest = socketRequest
    }
}

public protocol SocketInteractor {
    func execute(with context: SocketInteractorContext) throws
}

public final class DefaultSocketInteractor: SocketInteractor {
    private let unixSocketClient: UnixDomainSocketClient
    private let console: Console

    init(
        unixSocketClient: UnixDomainSocketClient,
        console: Console
    ) {
        self.unixSocketClient = unixSocketClient
        self.console = console
    }

    public func execute(with context: SocketInteractorContext) throws {
        let response: CurieSocketResponse = try unixSocketClient.send(
            request: context.socketRequest,
            socketPath: context.socketPath
        )
        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)
        console.text("\(jsonString ?? "")", always: true)
    }
}
