import CurieCommon
import CurieCommonMocks
import CurieCoreMocks
import Foundation
import XCTest

@testable import CurieCore

final class DownloadInteractorTests: XCTestCase {
    private var subject: DefaultDownloadInteractor!
    private var fileSystem: DefaultFileSystem!
    private var runLoop: DefaultRunLoop!
    private var restoreImageService: MockRestoreImageService!
    private var httpClient: MockHTTPClient!
    private var console: MockConsole!
    private var directory: Directory!

    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        super.setUp()
        httpClient = MockHTTPClient()
        console = MockConsole()
        restoreImageService = MockRestoreImageService()
        fileSystem = DefaultFileSystem()
        runLoop = DefaultRunLoop(interval: .short)
        subject = DefaultDownloadInteractor(
            restoreImageService: restoreImageService,
            httpClient: httpClient,
            fileSystem: fileSystem,
            runLoop: runLoop,
            console: console
        )

        try directory = fileSystem.makeTemporaryDirectory()
    }

    override func tearDown() {
        super.tearDown()
        httpClient = nil
        console = nil
        restoreImageService = nil
        fileSystem = nil
        runLoop = nil
        subject = nil

        directory = nil
    }

    func testExecute_validContext() throws {
        // Given
        let destination = directory.path.appending(component: "destination.ipsw")
        let context = DownloadInteractorContext(path: destination.pathString)
        restoreImageService.mockLatestSupported = [anyRestoreImage]
        httpClient.mockDownloadResult[anySourceURL] = try [anyDownload()]

        // When
        try subject.execute(with: context)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: destination.pathString))
        XCTAssertEqual(fileManager.contents(atPath: destination.pathString), anyContent.data(using: .utf8))
    }

    // MARK: - Private

    private func makeTemporaryFile() throws -> URL {
        let path = directory.path.appending(component: "\(UUID().uuidString).ipsw")
        try anyContent.write(to: path.asURL, atomically: true, encoding: .utf8)
        return path.asURL
    }

    private var anyContent: String {
        "TestContent"
    }

    private var anyRestoreImage: RestoreImage {
        .init(
            url: anySourceURL,
            isSupported: true,
            buildVersion: anyBuildVersion,
            operatingSystemVersion: anyOperatingSystemVersion
        )
    }

    private var anySourceURL: URL {
        URL(string: "https://apple.com/images/sample1")!
    }

    private var anyBuildVersion: String {
        "E10A"
    }

    private var anyOperatingSystemVersion: String {
        "14.5"
    }

    private func anyDownload() throws -> MockHTTPClient.MockDownload {
        try .init(url: makeTemporaryFile(), response: URLResponse(), progress: [
            .init(received: .init(bytes: 10), expected: .init(bytes: 100), progress: 0.1),
            .init(received: .init(bytes: 70), expected: .init(bytes: 100), progress: 0.7),
            .init(received: .init(bytes: 90), expected: .init(bytes: 100), progress: 0.9),
        ])
    }
}
