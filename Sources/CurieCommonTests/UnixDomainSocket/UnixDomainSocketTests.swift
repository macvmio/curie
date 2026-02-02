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
import XCTest

final class UnixDomainSocketTests: XCTestCase {
    struct RequestFromClient: Codable {
        let messageFromClient: String
    }

    struct ResponseFromServer: Codable {
        let messageFromServer: String
    }

    private lazy var server = UnixDomainSocketServer()
    private lazy var socketPath = "/tmp/testing_curie_socket_\(UUID().uuidString).sock"
    private lazy var client = UnixDomainSocketClient()

    private func sendMessageAndReceiveResponse(
        socketPath: String,
        clientMessage: String,
        expectedServerMessage: String
    ) throws {
        let responseFromServer: ResponseFromServer = try client.send(
            request: RequestFromClient(messageFromClient: clientMessage),
            socketPath: socketPath
        )
        XCTAssertEqual(responseFromServer.messageFromServer, expectedServerMessage)
    }

    func testSingle() throws {
        let serverHandlerCalled = expectation(description: "server handler has been called")

        _ = try server.start(
            socketPath: socketPath,
            responseProvider: { (requestFromClient: RequestFromClient) in
                XCTAssertEqual(requestFromClient.messageFromClient, "from client")
                serverHandlerCalled.fulfill()
                return Response(
                    payload: ResponseFromServer(messageFromServer: "from server"),
                    closeSocketAfterDeliveringResponse: false
                )
            },
            connectionQueue: .global()
        )

        try sendMessageAndReceiveResponse(
            socketPath: socketPath,
            clientMessage: "from client",
            expectedServerMessage: "from server"
        )
        wait(for: [serverHandlerCalled], timeout: 10)
    }

    func testSocketPathIsDeletedAfterDestroyingSocket() throws {
        XCTAssertFalse(
            FileManager().fileExists(atPath: socketPath),
            "Socket path \(socketPath) should not exist because socket is not created yet"
        )

        do {
            let serverHandlerCalled = expectation(description: "server handler has been called")

            let server = UnixDomainSocketServer()
            _ = try server.start(
                socketPath: socketPath,
                responseProvider: { (requestFromClient: RequestFromClient) in
                    XCTAssertEqual(requestFromClient.messageFromClient, "from client")
                    serverHandlerCalled.fulfill()
                    return Response(
                        payload: ResponseFromServer(messageFromServer: "from server"),
                        closeSocketAfterDeliveringResponse: false
                    )
                },
                connectionQueue: .global()
            )

            try sendMessageAndReceiveResponse(
                socketPath: socketPath,
                clientMessage: "from client",
                expectedServerMessage: "from server"
            )
            wait(for: [serverHandlerCalled], timeout: 10)

            XCTAssertTrue(
                FileManager().fileExists(atPath: socketPath),
                "Socket path \(socketPath) should exist because socket still exists"
            )
        }

        XCTAssertFalse(
            FileManager().fileExists(atPath: socketPath),
            "Socket path \(socketPath) should not exist because socket has been destroyed"
        )
    }

    func testRepeated() throws {
        _ = try server.start(
            socketPath: socketPath,
            responseProvider: { (requestFromClient: RequestFromClient) in
                Response(
                    payload: ResponseFromServer(
                        messageFromServer: "from server in response to: \(requestFromClient.messageFromClient)"
                    ),
                    closeSocketAfterDeliveringResponse: false
                )
            },
            connectionQueue: .global()
        )

        for idx in 1 ... 500 {
            try sendMessageAndReceiveResponse(
                socketPath: socketPath,
                clientMessage: "from client #\(idx)",
                expectedServerMessage: "from server in response to: from client #\(idx)"
            )
        }
    }

    func testClosingSocketAfterResponse() throws {
        _ = try server.start(
            socketPath: socketPath,
            responseProvider: { (_: RequestFromClient) in
                Response(
                    payload: ResponseFromServer(
                        messageFromServer: "from server"
                    ),
                    closeSocketAfterDeliveringResponse: true
                )
            },
            connectionQueue: .global()
        )

        let attempt: () throws -> Void = {
            try self.sendMessageAndReceiveResponse(
                socketPath: self.socketPath,
                clientMessage: "from client",
                expectedServerMessage: "from server"
            )
        }

        XCTAssertNoThrow(
            try attempt()
        )
        XCTAssertThrowsError(
            try attempt()
        )
    }
}
