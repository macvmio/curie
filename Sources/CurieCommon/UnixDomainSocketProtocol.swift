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

// MARK: - Request

public enum CurieSocketRequest {
    case ping(PingPayload)
    case terminateVm(TerminateVmPayload)
    case makeScreenshot(MakeScreenshotPayload)
    case synthesizeKeyboard(SynthesizeKeyboardPayload)
}

// MARK: Request Payloads

public struct PingPayload {
    public init() {}
}

public struct TerminateVmPayload {
    private static let waitToCompleteDefaultValue: Bool = true
    private static let defaultTimeout: TimeInterval = 10

    /// Should the caller wait for completion of the VM termination.
    public var waitToComplete: Bool

    /// Maximum time curie waits for VM to be terminated before considering the operation as timed out.
    public var timeout: TimeInterval

    public init(
        waitToComplete: Bool,
        timeout: TimeInterval
    ) {
        self.waitToComplete = waitToComplete
        self.timeout = timeout
    }
}

public struct MakeScreenshotPayload {
    public var savePngImageAtPath: String

    public init(savePngImageAtPath: String) {
        self.savePngImageAtPath = savePngImageAtPath
    }
}

public struct SynthesizeKeyboardPayload {
    public var input: KeyboardInput

    public init(input: KeyboardInput) {
        self.input = input
    }
}

// MARK: - Response

public enum CurieSocketResponse {
    case success([String: ResponseValue])
    case error(String)
}

// MARK: Response Payloads

public enum ResponseValue {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
}

// MARK: - Codable support for nicer JSON

public extension CurieSocketRequest {
    var intentHumanReadableDescription: String {
        switch self {
        case .ping:
            "Ping the server"
        case .terminateVm:
            "Terminate the VM"
        case .makeScreenshot:
            "Make screenshot"
        case .synthesizeKeyboard:
            "Synthesize keyboard input"
        }
    }
}

extension CurieSocketRequest: Codable {
    private enum RequestKey: String, CodingKey, CaseIterable {
        case ping
        case terminateVm
        case makeScreenshot
        case synthesizeKeyboard
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RequestKey.self)

        guard container.allKeys.count == 1, let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a single key from \(RequestKey.allCases), " +
                        "but found multiple keys: \(container.allKeys)"
                )
            )
        }

        switch key {
        case .ping:
            let payload = try container.decode(PingPayload.self, forKey: .ping)
            self = .ping(payload)
        case .terminateVm:
            let payload = try container.decode(TerminateVmPayload.self, forKey: .terminateVm)
            self = .terminateVm(payload)
        case .makeScreenshot:
            let payload = try container.decode(MakeScreenshotPayload.self, forKey: .makeScreenshot)
            self = .makeScreenshot(payload)
        case .synthesizeKeyboard:
            let payload = try container.decode(SynthesizeKeyboardPayload.self, forKey: .synthesizeKeyboard)
            self = .synthesizeKeyboard(payload)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RequestKey.self)
        switch self {
        case let .ping(payload):
            try container.encode(payload, forKey: .ping)
        case let .terminateVm(payload):
            try container.encode(payload, forKey: .terminateVm)
        case let .makeScreenshot(payload):
            try container.encode(payload, forKey: .makeScreenshot)
        case let .synthesizeKeyboard(payload):
            try container.encode(payload, forKey: .synthesizeKeyboard)
        }
    }
}

extension CurieSocketResponse: Codable {
    private enum CondingKeys: String, CodingKey, CaseIterable {
        case success
        case error
    }

    public init(from decoder: Decoder) throws {
        let primary = try decoder.container(keyedBy: CondingKeys.self)
        let keys = primary.allKeys
        if keys.count == 1, let key = keys.first {
            switch key {
            case .success:
                let payload = try primary.decode([String: ResponseValue].self, forKey: .success)
                self = .success(payload)
                return
            case .error:
                let message = try primary.decode(String.self, forKey: .error)
                self = .error(message)
                return
            }
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "CurieSocketResponse expects either { 'ok': {...} } or { 'error': '...' }."
        ))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CondingKeys.self)
        switch self {
        case let .success(dict):
            try container.encode(dict, forKey: .success)
        case let .error(message):
            try container.encode(message, forKey: .error)
        }
    }
}

extension ResponseValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            throw DecodingError.typeMismatch(
                ResponseValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ResponseValue expects a single value of type String, Bool, Int, or Double."
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        }
    }
}

extension PingPayload: Codable {}

extension TerminateVmPayload: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        waitToComplete = try container.decodeIfPresent(Bool.self, forKey: .waitToComplete) ?? Self
            .waitToCompleteDefaultValue
        timeout = try container.decodeIfPresent(TimeInterval.self, forKey: .timeout) ?? Self.defaultTimeout
    }

    enum CodingKeys: CodingKey {
        case waitToComplete
        case timeout
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if waitToComplete != Self.waitToCompleteDefaultValue {
            try container.encode(waitToComplete, forKey: .waitToComplete)
        }
        if timeout != Self.defaultTimeout {
            try container.encode(timeout, forKey: .timeout)
        }
    }
}

extension MakeScreenshotPayload: Codable {}

extension SynthesizeKeyboardPayload: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        input = try container.decode(KeyboardInput.self, forKey: .input)
    }

    enum CodingKeys: CodingKey {
        case input
        case waitToComplete
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(input, forKey: .input)
    }
}
