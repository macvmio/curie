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
import CurieCommonMocks
import CurieCoreMocks
import Foundation
import SCInject
import XCTest

@testable import CurieCore

final class DownloadInteractorTests: XCTestCase {
    private var subject: Interactor!
    private var env: InteractorsTestsEnvironment!
    private var directory: TemporaryDirectory!

    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        super.setUp()
        env = InteractorsTestsEnvironment()
        directory = try TemporaryDirectory()
        subject = env.resolveInteractor()
    }

    override func tearDown() {
        super.tearDown()
        env = nil
        directory = nil
        subject = nil
    }

    func testExecute_validParameters() throws {
        // Given
        let destination = directory.path.appending(component: "destination.ipsw")
        let parameters = DownloadParameters(path: destination.pathString)
        env.restoreImageService.mockLatestSupported = [anyRestoreImage]
        env.httpClient.mockDownloadResult[anySourceURL] = try [anyDownload()]

        // When
        try subject.execute(.download(parameters))

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: destination.pathString))
        XCTAssertEqual(fileManager.contents(atPath: destination.pathString), anyContent.data(using: .utf8))
    }

    func testExecute_existingDirectory() throws {
        // Given
        let parameters = DownloadParameters(path: "/")

        // When / Then
        try XCTAssertError(subject.execute(.download(parameters)), .init(
            message: "Directory already exists at path",
            metadata: ["PATH": "/"]
        ))
    }

    func testExecute_existingFile() throws {
        // Given
        let destination = directory.path.appending(component: "destination.ipsw")
        let parameters = DownloadParameters(path: destination.pathString)
        try "file".write(to: destination.asURL, atomically: true, encoding: .utf8)

        // When / Then
        try XCTAssertError(subject.execute(.download(parameters)), .init(
            message: "File already exists at path",
            metadata: ["PATH": destination.pathString]
        ))
    }

    func testExecute_unsupportedImage() throws {
        // Given
        var storeImage = anyRestoreImage
        storeImage.isSupported = false

        let destination = directory.path.appending(component: "destination.ipsw")
        let parameters = DownloadParameters(path: destination.pathString)
        env.restoreImageService.mockLatestSupported = [storeImage]
        env.httpClient.mockDownloadResult[anySourceURL] = try [anyDownload()]

        // When / Then
        try XCTAssertError(subject.execute(.download(parameters)), .init(
            message: "Latest image is not supported",
            metadata: ["OS_VERSION": "14.5", "BUILD_VERSION": "E10A"]
        ))
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
