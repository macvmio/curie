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
