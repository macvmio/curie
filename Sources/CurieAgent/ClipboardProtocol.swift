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

import Foundation

enum ClipboardConstants {
    /// Magic bytes for protocol identification: "CURI"
    static let magic: UInt32 = 0x4355_5249

    /// Virtio socket port for clipboard sync
    static let port: UInt32 = 52525

    /// Virtio socket CID for host
    static let hostCID: UInt32 = 2

    /// Header size in bytes: magic(4) + type(1) + seqNum(4) + length(4) = 13
    static let headerSize = 13

    /// Maximum payload size (1 MB)
    static let maxPayloadSize = 1024 * 1024
}

enum ClipboardMessageType: UInt8 {
    /// Notify the other side that clipboard content has changed
    case clipboardChanged = 0x01

    /// Send clipboard content data
    case clipboardData = 0x02

    /// Request clipboard content from the other side
    case clipboardRequest = 0x03

    /// Keepalive ping
    case ping = 0x04

    /// Keepalive pong response
    case pong = 0x05
}

enum ClipboardContentType: String, Codable {
    case plainText = "public.utf8-plain-text"
    case rtf = "public.rtf"
    case png = "public.png"
    case tiff = "public.tiff"
}

struct ClipboardContent: Codable, Equatable {
    var type: ClipboardContentType
    var data: Data
    var changeCount: Int
}

struct ClipboardMessage {
    var type: ClipboardMessageType
    var sequenceNumber: UInt32
    var payload: Data

    init(type: ClipboardMessageType, sequenceNumber: UInt32, payload: Data = Data()) {
        self.type = type
        self.sequenceNumber = sequenceNumber
        self.payload = payload
    }

    func encode() -> Data {
        var data = Data()

        // Magic (4 bytes, big-endian)
        var magic = ClipboardConstants.magic.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &magic) { Array($0) })

        // Type (1 byte)
        data.append(type.rawValue)

        // Sequence number (4 bytes, big-endian)
        var seqNum = sequenceNumber.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &seqNum) { Array($0) })

        // Length (4 bytes, big-endian)
        var length = UInt32(payload.count).bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &length) { Array($0) })

        // Payload
        data.append(payload)

        return data
    }

    static func decode(from data: Data) -> (message: ClipboardMessage, bytesConsumed: Int)? {
        guard data.count >= ClipboardConstants.headerSize else {
            return nil
        }

        // Read magic (bytes 0-3)
        let magic = readUInt32(from: data, at: 0)
        guard magic == ClipboardConstants.magic else {
            return nil
        }

        // Read type (byte 4)
        guard let messageType = ClipboardMessageType(rawValue: data[data.startIndex + 4]) else {
            return nil
        }

        // Read sequence number (bytes 5-8)
        let seqNum = readUInt32(from: data, at: 5)

        // Read length (bytes 9-12)
        let length = readUInt32(from: data, at: 9)

        let totalSize = ClipboardConstants.headerSize + Int(length)
        guard data.count >= totalSize else {
            return nil
        }

        guard length <= ClipboardConstants.maxPayloadSize else {
            return nil
        }

        let payloadStart = data.startIndex + ClipboardConstants.headerSize
        let payloadEnd = payloadStart + Int(length)
        let payload = data[payloadStart ..< payloadEnd]
        let message = ClipboardMessage(type: messageType, sequenceNumber: seqNum, payload: Data(payload))

        return (message, totalSize)
    }

    private static func readUInt32(from data: Data, at offset: Int) -> UInt32 {
        let index = data.startIndex + offset
        let byte0 = UInt32(data[index]) << 24
        let byte1 = UInt32(data[index + 1]) << 16
        let byte2 = UInt32(data[index + 2]) << 8
        let byte3 = UInt32(data[index + 3])
        return byte0 | byte1 | byte2 | byte3
    }
}

extension ClipboardMessage {
    static func clipboardChanged(sequenceNumber: UInt32, changeCount: Int) -> ClipboardMessage {
        var payload = Data()
        var count = UInt32(changeCount).bigEndian
        payload.append(contentsOf: withUnsafeBytes(of: &count) { Array($0) })
        return ClipboardMessage(type: .clipboardChanged, sequenceNumber: sequenceNumber, payload: payload)
    }

    static func clipboardData(sequenceNumber: UInt32, content: ClipboardContent) -> ClipboardMessage? {
        guard let payload = try? JSONEncoder().encode(content) else {
            return nil
        }
        return ClipboardMessage(type: .clipboardData, sequenceNumber: sequenceNumber, payload: payload)
    }

    static func clipboardRequest(sequenceNumber: UInt32) -> ClipboardMessage {
        ClipboardMessage(type: .clipboardRequest, sequenceNumber: sequenceNumber)
    }

    static func ping(sequenceNumber: UInt32) -> ClipboardMessage {
        ClipboardMessage(type: .ping, sequenceNumber: sequenceNumber)
    }

    static func pong(sequenceNumber: UInt32) -> ClipboardMessage {
        ClipboardMessage(type: .pong, sequenceNumber: sequenceNumber)
    }

    func parseClipboardContent() -> ClipboardContent? {
        guard type == .clipboardData else {
            return nil
        }
        return try? JSONDecoder().decode(ClipboardContent.self, from: payload)
    }

    func parseChangeCount() -> Int? {
        guard type == .clipboardChanged, payload.count >= 4 else {
            return nil
        }
        let count = ClipboardMessage.readUInt32(from: payload, at: 0)
        return Int(count)
    }
}
