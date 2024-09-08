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
import TSCBasic

public struct HTTPClientDownloadProgress {
    public let received: MemorySize
    public let expected: MemorySize
    public let progress: Double

    public init(received: MemorySize, expected: MemorySize, progress: Double) {
        self.received = received
        self.expected = expected
        self.progress = progress
    }
}

public protocol HTTPClientDownloadTracker: AnyObject {
    func httpClient(_ httpClient: HTTPClient, progress: HTTPClientDownloadProgress)
}

public protocol HTTPClient {
    func download(url: URL, tracker: (any HTTPClientDownloadTracker)?) async throws -> (URL, URLResponse)
}

public final class URLSessionHTTPClient: HTTPClient {
    private let urlSession = URLSession.shared

    public func download(url: URL, tracker: (any HTTPClientDownloadTracker)?) async throws -> (URL, URLResponse) {
        var observer: NSKeyValueObservation?
        let result: (url: URL, _: URLResponse) = try await withCheckedThrowingContinuation { [self] continuation in
            let task = urlSession.downloadTask(with: url) { url, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url, let response {
                    continuation.resume(returning: (url, response))
                } else {
                    continuation.resume(throwing: CoreError.generic("Unexpected result"))
                }
            }
            if let tracker {
                observer = task.progress.observe(\.fractionCompleted, options: [.initial, .new]) { _, _ in
                    let received = MemorySize(bytes: UInt64(task.countOfBytesReceived))
                    let expected = MemorySize(bytes: UInt64(task.countOfBytesExpectedToReceive))
                    let progress = expected.bytes > 0 ? Double(received.bytes) / Double(expected.bytes) : 0.0
                    tracker.httpClient(
                        self,
                        progress: .init(received: received, expected: expected, progress: progress)
                    )
                }
            }
            task.resume()
        }
        withExtendedLifetime(observer) {}
        return result
    }
}
