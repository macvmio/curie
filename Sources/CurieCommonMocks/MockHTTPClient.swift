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
import Foundation

public final class MockHTTPClient: HTTPClient {
    public struct MockDownload {
        public var url: URL
        public let response: URLResponse
        public var progress: [HTTPClientDownloadProgress]

        public init(url: URL, response: URLResponse, progress: [HTTPClientDownloadProgress]) {
            self.url = url
            self.response = response
            self.progress = progress
        }
    }

    public var mockDownloadResult: [URL: [MockDownload]] = [:]

    public init() {}

    public func download(url: URL, tracker: (any HTTPClientDownloadTracker)?) async throws -> (URL, URLResponse) {
        guard let download = mockDownloadResult[url]?.popLast() else {
            fatalError("Missing mock download")
        }

        for item in download.progress {
            tracker?.httpClient(self, progress: item)
        }

        return (download.url, download.response)
    }
}
