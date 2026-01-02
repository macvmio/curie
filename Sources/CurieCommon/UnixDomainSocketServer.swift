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

import Darwin
import Foundation

public struct ErrorResponse: Codable {
    public let reason: String
}

public final class ServerListeningHandle {
    public let socketPath: String
    public let fileDescriptor: Int32
    public private(set) var isListening: Bool

    public init(
        socketPath: String,
        fileDescriptor: Int32,
        isListening: Bool
    ) {
        self.socketPath = socketPath
        self.fileDescriptor = fileDescriptor
        self.isListening = isListening
    }

    public func close() {
        isListening = false
        Darwin.close(fileDescriptor)
        Darwin.unlink(socketPath)
    }
}

public final class UnixDomainSocketServer {
    private var trackedHandles: [ServerListeningHandle] = []

    public init() {}

    deinit {
        for trackedHandle in trackedHandles {
            trackedHandle.close()
        }
    }

    public func start<Request: Codable>(
        socketPath: String,
        handler: @escaping (Request) -> some Codable,
        connectionQueue: DispatchQueue
    ) throws -> ServerListeningHandle {
        let serverFileDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)

        guard serverFileDescriptor >= 0 else {
            throw NSError(domain: "SocketFileDescriptorError", code: 1)
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        strcpy(&addr.sun_path.0, socketPath)

        var bindAddr = addr
        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFileDescriptor, $0, socklen_t(MemoryLayout.size(ofValue: addr)))
            }
        }
        guard bindResult == 0 else {
            throw NSError(domain: "SocketBindError", code: 2)
        }

        listen(serverFileDescriptor, 10)

        let listeningHandle = ServerListeningHandle(
            socketPath: socketPath,
            fileDescriptor: serverFileDescriptor,
            isListening: true
        )

        connectionQueue.async { [weak self] in
            while listeningHandle.isListening {
                var clientAddr = sockaddr()
                var clientLen: socklen_t = .init(MemoryLayout<sockaddr>.size)
                let clientFileDescriptor = accept(serverFileDescriptor, &clientAddr, &clientLen)
                if clientFileDescriptor < 0 {
                    continue
                }

                connectionQueue.async { [weak self] in
                    guard let strongSelf = self else {
                        listeningHandle.close()
                        return
                    }
                    strongSelf.handleClient(clientFileDescriptor: clientFileDescriptor, handler: handler)
                }
            }
            listeningHandle.close()
        }

        trackedHandles.append(listeningHandle)

        return listeningHandle
    }

    private func handleClient<Request: Codable, Response: Codable>(
        clientFileDescriptor: Int32,
        handler: (Request) -> Response
    ) {
        defer {
            close(clientFileDescriptor)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = read(clientFileDescriptor, &buffer, buffer.count)
        guard count > 0 else {
            return
        }

        let data = Data(buffer[0 ..< count])
        guard let request = try? JSONDecoder().decode(Request.self, from: data) else {
            send(response: ErrorResponse(reason: "Invalid request"), to: clientFileDescriptor)
            return
        }

        let response: Response = handler(request)
        send(response: response, to: clientFileDescriptor)
    }

    private func send(
        response: some Codable,
        to fileDescriptor: Int32
    ) {
        guard let outData = try? JSONEncoder().encode(response) else {
            return
        }
        _ = outData.withUnsafeBytes {
            write(fileDescriptor, $0.baseAddress, outData.count)
        }
    }
}
