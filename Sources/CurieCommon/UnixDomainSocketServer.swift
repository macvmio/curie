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
    private let lock = NSLock()

    public init(
        socketPath: String,
        fileDescriptor: Int32
    ) {
        self.socketPath = socketPath
        self.fileDescriptor = fileDescriptor
        isListening = true
    }

    public func close() {
        lock.withLock {
            if !isListening {
                return
            }
            isListening = false
            Darwin.close(fileDescriptor)
            Darwin.unlink(socketPath)
        }
    }
}

public struct Response<T: Codable> {
    public let payload: T

    /// When set to `true` it essentially means the process will be terminating after processing this request, so the
    /// socket should be terminated gracefully after delivering this response.
    public let closeSocketAfterDeliveringResponse: Bool

    public init(payload: T, closeSocketAfterDeliveringResponse: Bool) {
        self.payload = payload
        self.closeSocketAfterDeliveringResponse = closeSocketAfterDeliveringResponse
    }
}

public final class UnixDomainSocketServer {
    private let lock = NSLock()
    private var trackedHandles: [ServerListeningHandle] = []

    public init() {}

    deinit {
        try? close()
    }

    public func close() throws {
        try lock.withLock {
            for trackedHandle in trackedHandles {
                trackedHandle.close()
            }
            let fileManager = FileManager()
            for trackedHandle in trackedHandles where fileManager.fileExists(atPath: trackedHandle.socketPath) {
                try fileManager.removeItem(atPath: trackedHandle.socketPath)
            }
        }
    }

    public func start<RequestPayload: Codable>(
        socketPath: String,
        responseProvider: @escaping (RequestPayload) -> Response<some Codable>,
        connectionQueue: DispatchQueue
    ) throws -> ServerListeningHandle {
        let serverFileDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)

        guard serverFileDescriptor >= 0 else {
            throw CoreError.generic("Failed to create socket at \(socketPath) with error num \(errno)")
        }

        let addr = try UnixDomainSocketUtil.createSockaddr(socketPath: socketPath)

        var bindAddr = addr
        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFileDescriptor, $0, socklen_t(MemoryLayout.size(ofValue: addr)))
            }
        }
        guard bindResult == 0 else {
            throw CoreError.generic("Failed to bind socket at \(socketPath) with error num \(errno)")
        }

        let backlog: Int32 = 10
        if listen(serverFileDescriptor, backlog) != 0 {
            throw CoreError.generic("Failed to listen to socket at \(socketPath) with error num \(errno)")
        }

        let listeningHandle = ServerListeningHandle(
            socketPath: socketPath,
            fileDescriptor: serverFileDescriptor
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
                    strongSelf.handleClient(
                        listeningHandle: listeningHandle,
                        clientFileDescriptor: clientFileDescriptor,
                        responseProvider: responseProvider
                    )
                }
            }
            listeningHandle.close()
        }

        trackedHandles.append(listeningHandle)

        return listeningHandle
    }

    private func handleClient<RequestPayload: Codable, ResponsePayload: Codable>(
        listeningHandle: ServerListeningHandle,
        clientFileDescriptor: Int32,
        responseProvider: (RequestPayload) -> Response<ResponsePayload>
    ) {
        defer {
            Darwin.close(clientFileDescriptor)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = read(clientFileDescriptor, &buffer, buffer.count)
        guard count > 0 else {
            return
        }

        let data = Data(buffer[0 ..< count])
        guard let request = try? JSONDecoder().decode(RequestPayload.self, from: data) else {
            send(payload: ErrorResponse(reason: "Invalid request"), to: clientFileDescriptor)
            return
        }

        let response: Response<ResponsePayload> = responseProvider(request)
        send(payload: response.payload, to: clientFileDescriptor)

        if response.closeSocketAfterDeliveringResponse {
            listeningHandle.close()
        }
    }

    private func send(
        payload: some Codable,
        to fileDescriptor: Int32
    ) {
        guard let outData = try? JSONEncoder().encode(payload) else {
            return
        }
        _ = outData.withUnsafeBytes {
            write(fileDescriptor, $0.baseAddress, outData.count)
        }
    }
}
