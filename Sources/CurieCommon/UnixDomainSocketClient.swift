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

import Foundation

public final class UnixDomainSocketClient {
    public init() {}

    public func send<Response: Codable>(
        request: some Codable,
        socketPath: String
    ) throws -> Response {
        let clientFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard clientFD >= 0 else {
            throw NSError(domain: "SocketError", code: 1)
        }
        defer {
            close(clientFD)
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        strcpy(&addr.sun_path.0, socketPath)

        var bindAddr = addr

        let connectResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(clientFD, $0, socklen_t(MemoryLayout.size(ofValue: addr)))
            }
        }
        guard connectResult == 0 else {
            throw NSError(domain: "ConnectError", code: 2)
        }

        let reqData = try JSONEncoder().encode(request)
        _ = reqData.withUnsafeBytes {
            write(clientFD, $0.baseAddress, reqData.count)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = read(clientFD, &buffer, buffer.count)
        guard count > 0 else {
            throw NSError(domain: "ReadError", code: 3)
        }

        let data = Data(buffer[0 ..< count])
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
