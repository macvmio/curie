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

public protocol PromisedSocketResponse {
    func getSocketResponse() -> CurieSocketResponse

    var closeSocketAfterDeliveringResponse: Bool { get }
}

public final class ConstantPromisedSocketResponse: PromisedSocketResponse {
    private let response: CurieSocketResponse
    public let closeSocketAfterDeliveringResponse: Bool

    public init(response: CurieSocketResponse, closeSocketAfterDeliveringResponse: Bool) {
        self.response = response
        self.closeSocketAfterDeliveringResponse = closeSocketAfterDeliveringResponse
    }

    public func getSocketResponse() -> CurieSocketResponse {
        response
    }
}

public final class BlockingSocketResponse: PromisedSocketResponse {
    private let value = UnsetValue<CurieSocketResponse>()
    private let timeout: TimeInterval
    public let closeSocketAfterDeliveringResponse: Bool

    public init(
        timeout: TimeInterval,
        closeSocketAfterDeliveringResponse: Bool
    ) {
        self.timeout = timeout
        self.closeSocketAfterDeliveringResponse = closeSocketAfterDeliveringResponse
    }

    public func set(response: CurieSocketResponse) {
        value.set(newValue: response)
    }

    public func getSocketResponse() -> CurieSocketResponse {
        let result = value.waitForNextValue(timeout: .now() + timeout)
        switch result {
        case .notSet:
            return .error("Time out")
        case let .value(curieSocketResponse):
            return curieSocketResponse
        }
    }
}

final class UnsetValue<T> {
    enum Box<R> {
        case notSet
        case value(R)
    }

    private let value: Atomic<Box<T>> = Atomic(value: Box.notSet)
    private let resultSet = DispatchGroup()
    private let queue = DispatchQueue(label: "UnsetValue<\(T.self)>.queue", target: .global())

    init() {
        resultSet.enter()
    }

    func set(newValue: T) {
        value.update(Box.value(newValue))
        resultSet.leave()
        resultSet.enter()
    }

    func waitForNextValue(timeout: DispatchTime) -> Box<T> {
        _ = resultSet.wait(timeout: timeout)
        return value.load()
    }
}
