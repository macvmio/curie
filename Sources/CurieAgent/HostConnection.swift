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

import Darwin
import Foundation

// AF_VSOCK constants - must match kernel values
private let afVsock: Int32 = 40
private let vmaddrCIDHost: UInt32 = 2

// sockaddr_vm structure for vsock connections - must match kernel structure layout
struct SockaddrVM {
    var svmLen: UInt8
    var svmFamily: UInt8
    var svmReserved1: UInt16
    var svmPort: UInt32
    var svmCid: UInt32
}

protocol HostConnectionDelegate: AnyObject {
    func connectionDidConnect(_ connection: HostConnection)
    func connectionDidDisconnect(_ connection: HostConnection)
    func connection(_ connection: HostConnection, didReceive message: ClipboardMessage)
}

final class HostConnection {
    weak var delegate: HostConnectionDelegate?

    private var socketFd: Int32 = -1
    private var isConnected = false
    private var receiveBuffer = Data()
    private var readSource: DispatchSourceRead?

    private let connectionQueue = DispatchQueue(label: "com.curie.agent.connection")

    func connect() {
        connectionQueue.async { [weak self] in
            self?.performConnect()
        }
    }

    func disconnect() {
        connectionQueue.async { [weak self] in
            self?.performDisconnect()
        }
    }

    func send(_ message: ClipboardMessage) {
        connectionQueue.async { [weak self] in
            self?.performSend(message)
        }
    }

    // MARK: - Private

    private func performConnect() {
        guard !isConnected else { return }

        // Create vsock socket
        socketFd = socket(afVsock, SOCK_STREAM, 0)
        guard socketFd >= 0 else {
            print("curie-agent: Failed to create vsock socket: \(errno)")
            scheduleReconnect()
            return
        }

        // Set up SockaddrVM for host connection
        var addr = SockaddrVM(
            svmLen: UInt8(MemoryLayout<SockaddrVM>.size),
            svmFamily: UInt8(afVsock),
            svmReserved1: 0,
            svmPort: ClipboardConstants.port,
            svmCid: vmaddrCIDHost
        )

        // Connect to host
        let result = withUnsafePointer(to: &addr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                Darwin.connect(socketFd, sockaddrPtr, socklen_t(MemoryLayout<SockaddrVM>.size))
            }
        }

        if result < 0 {
            print("curie-agent: Failed to connect to host: \(errno)")
            close(socketFd)
            socketFd = -1
            scheduleReconnect()
            return
        }

        isConnected = true
        print("curie-agent: Connected to host on port \(ClipboardConstants.port)")

        startReading()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            delegate?.connectionDidConnect(self)
        }
    }

    private func performDisconnect() {
        readSource?.cancel()
        readSource = nil

        if socketFd >= 0 {
            close(socketFd)
            socketFd = -1
        }

        let wasConnected = isConnected
        isConnected = false
        receiveBuffer.removeAll()

        if wasConnected {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                delegate?.connectionDidDisconnect(self)
            }
        }
    }

    private func performSend(_ message: ClipboardMessage) {
        guard isConnected, socketFd >= 0 else { return }

        let data = message.encode()
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            let bytesWritten = write(socketFd, baseAddress, buffer.count)
            if bytesWritten < 0 {
                print("curie-agent: Failed to write to socket: \(errno)")
                performDisconnect()
                scheduleReconnect()
            }
        }
    }

    private func startReading() {
        readSource = DispatchSource.makeReadSource(fileDescriptor: socketFd, queue: connectionQueue)
        readSource?.setEventHandler { [weak self] in
            self?.handleReadEvent()
        }
        readSource?.setCancelHandler { [weak self] in
            // Clean up if needed
            _ = self
        }
        readSource?.resume()
    }

    private func handleReadEvent() {
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(socketFd, &buffer, buffer.count)

        if bytesRead <= 0 {
            print("curie-agent: Connection closed by host")
            performDisconnect()
            scheduleReconnect()
            return
        }

        receiveBuffer.append(contentsOf: buffer[0 ..< bytesRead])
        processReceivedData()
    }

    private func processReceivedData() {
        while let (message, bytesConsumed) = ClipboardMessage.decode(from: receiveBuffer) {
            receiveBuffer.removeFirst(bytesConsumed)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                delegate?.connection(self, didReceive: message)
            }
        }
    }

    private func scheduleReconnect() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }
}
