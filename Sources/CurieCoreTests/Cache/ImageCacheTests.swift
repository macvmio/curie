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

@testable import CurieCommon
import CurieCommonMocks
@testable import CurieCore
import Foundation
import TSCBasic
import XCTest

final class ImageCacheTests: XCTestCase {
    private var subject: DefaultImageCache!
    private var fileSystem: CurieCommon.FileSystem!
    private var bundleParser: VMBundleParser!
    private var wallClock: MockWallClock!
    private var system: MockSystem!

    private var fixtures: Fixtures!
    private var environment: FileSystemEnvironment!

    override func setUpWithError() throws {
        super.setUp()
        fixtures = Fixtures()
        environment = try FileSystemEnvironment.make()
        wallClock = MockWallClock()
        wallClock.mockNow = .distantPast
        fileSystem = DefaultFileSystem(config: .init(overrides: .init(
            currentWorkingDirectory: environment.currentWorkingDirectory,
            homeDirectory: environment.homeDirectory
        )))
        bundleParser = DefaultVMBundleParser(fileSystem: fileSystem)
        system = MockSystem()
        subject = DefaultImageCache(
            bundleParser: bundleParser,
            wallClock: wallClock,
            system: system,
            fileSystem: fileSystem
        )
    }

    override func tearDown() {
        super.tearDown()
        fixtures = nil
        environment = nil
        wallClock = nil
        bundleParser = nil
        system = nil
        subject = nil
    }

    func testMakeImageReference_onlyRepository() throws {
        // When
        let result = try subject.makeImageReference(anyReference)

        // Then
        XCTAssertEqual(result.id.description.count, 12)
        XCTAssertEqual(result.descriptor, .init(repository: anyReference, tag: nil))
        XCTAssertEqual(result.type, .image)
    }

    func testMakeImageReference_repositoryAndTag() throws {
        // When
        let result = try subject.makeImageReference("\(anyReference):\(anyTag)")

        // Then
        XCTAssertEqual(result.id.description.count, 12)
        XCTAssertEqual(result.descriptor, .init(repository: anyReference, tag: anyTag))
        XCTAssertEqual(result.type, .image)
    }

    func testFindReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the container")
        }
    }

    func testFindContainerReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findContainerReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the container")
        }
    }

    func testFindImageReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findImageReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the image")
        }
    }

    func testFindImageReference_repositoryAndTag() throws {
        // Given
        try importAnyImage(reference: "test/image1:1.0")
        try importAnyImage(reference: "test/image1:1.2")

        // When
        let result = try subject.findImageReference("test/image1:1.2")

        // Then
        XCTAssertEqual(result.descriptor, .init(repository: "test/image1", tag: "1.2"))
        XCTAssertEqual(result.type, .image)
    }

    func testListImages_noImages() throws {
        // When / Then
        XCTAssertEqual(try subject.listImages(), [])
    }

    func testListImages_someImages() throws {
        // Given
        try importAnyImage(reference: "test/image1:1.0")
        try importAnyImage(reference: "test/image1:1.2")

        // When
        let results = try subject.listImages()

        // Then
        XCTAssertEqual(results, [
            .init(
                reference: .init(
                    id: .init(rawValue: "1"),
                    descriptor: .init(repository: "test/image1", tag: "1.0"),
                    type: .image
                ),
                createAt: wallClock.now(),
                size: .init(string: "543 B")!,
                name: "metadata-name"
            ),
            .init(
                reference: .init(
                    id: .init(rawValue: "2"),
                    descriptor: .init(repository: "test/image1", tag: "1.2"),
                    type: .image
                ),
                createAt: wallClock.now(),
                size: .init(string: "543 B")!,
                name: "metadata-name"
            ),
        ])
    }

    func testListContainers_noContainers() throws {
        // When / Then
        XCTAssertEqual(try subject.listContainers(), [])
    }

    func testListContainers_someContainers() throws {
        // Given
        try importAnyImage(reference: "test/image1:1.0")
        try importAnyImage(reference: "test/image1:1.2")
        let anyImage1 = try subject.findImageReference("test/image1:1.0")

        try subject.moveImage(
            source: anyImage1,
            target: .init(id: .make(), descriptor: .init(reference: "test/container:1.0"), type: .container)
        )

        // Then
        XCTAssertEqual(try subject.listContainers(), try [
            .init(
                reference: .init(
                    id: .init(rawValue: "1"),
                    descriptor: .init(reference: "test/container:1.0"),
                    type: .container
                ),
                createAt: .distantPast,
                size: .init(bytes: 543),
                name: "metadata-name"
            ),
        ])
    }

    func testPath() throws {
        // Given
        let expectedPath = try environment.homeDirectory.appending(
            RelativePath(validating: ".curie/.images/\(anyReference)")
        )

        // When
        let path = try subject.path(
            to: .init(
                id: .init(rawValue: "image-id"),
                descriptor: .init(reference: anyReference),
                type: .image
            )
        )

        // Then
        XCTAssertEqual(path, expectedPath)
    }

    func testImportImage() throws {
        // Given
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        let expectedBundlePath = try environment.homeDirectory.appending(
            RelativePath(validating: ".curie/.images/\(anyReference)")
        )

        // When
        try subject.importImage(sourcePath: bundle.path.pathString, reference: anyReference)

        // Then
        let files = try fileSystem.list(at: expectedBundlePath)
        XCTAssertEqual(files, try [
            .file(.init(path: .init(validating: "auxilary-storage.bin"))),
            .file(.init(path: .init(validating: "config.json"))),
            .file(.init(path: .init(validating: "disk.img"))),
            .file(.init(path: .init(validating: "hardware-model.bin"))),
            .file(.init(path: .init(validating: "machine-identifier.bin"))),
            .file(.init(path: .init(validating: "metadata.json"))),
        ])
        XCTAssertBundlesEqual(bundle, path: expectedBundlePath)
    }

    func testImportImageWithDataRoot() throws {
        // Given
        system.mockEnvironmentVariables = [
            "CURIE_DATA_ROOT": environment.temporaryDirectory.appending(component: ".curie-custom").pathString,
        ]
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        let expectedBundlePath = try environment.temporaryDirectory.appending(component: ".curie-custom")
            .appending(RelativePath(validating: ".images/\(anyReference)"))

        // When
        try subject.importImage(sourcePath: bundle.path.pathString, reference: anyReference)

        // Then
        let files = try fileSystem.list(at: expectedBundlePath)
        XCTAssertEqual(files, try [
            .file(.init(path: .init(validating: "auxilary-storage.bin"))),
            .file(.init(path: .init(validating: "config.json"))),
            .file(.init(path: .init(validating: "disk.img"))),
            .file(.init(path: .init(validating: "hardware-model.bin"))),
            .file(.init(path: .init(validating: "machine-identifier.bin"))),
            .file(.init(path: .init(validating: "metadata.json"))),
        ])
        XCTAssertBundlesEqual(bundle, path: expectedBundlePath)
    }

    func testImportImageWithRelativeDataRoot() throws {
        // Given
        system.mockEnvironmentVariables = [
            "CURIE_DATA_ROOT": ".curie-custom",
        ]
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        let expectedBundlePath = try environment.currentWorkingDirectory.appending(component: ".curie-custom")
            .appending(RelativePath(validating: ".images/\(anyReference)"))

        // When
        try subject.importImage(sourcePath: bundle.path.pathString, reference: anyReference)

        // Then
        let files = try fileSystem.list(at: expectedBundlePath)
        XCTAssertEqual(files, try [
            .file(.init(path: .init(validating: "auxilary-storage.bin"))),
            .file(.init(path: .init(validating: "config.json"))),
            .file(.init(path: .init(validating: "disk.img"))),
            .file(.init(path: .init(validating: "hardware-model.bin"))),
            .file(.init(path: .init(validating: "machine-identifier.bin"))),
            .file(.init(path: .init(validating: "metadata.json"))),
        ])
        XCTAssertBundlesEqual(bundle, path: expectedBundlePath)
    }

    func testExportImageRaw() throws {
        // Given
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        let expectedBundlePath = try environment.currentWorkingDirectory.appending(
            RelativePath(validating: "test/export")
        )
        try subject.importImage(sourcePath: bundle.path.pathString, reference: anyReference)
        let imageReference = try subject.findImageReference(anyReference)

        // When
        try subject.exportImage(
            source: imageReference,
            destinationPath: expectedBundlePath.pathString,
            mode: .raw
        )

        // Then
        let files = try fileSystem.list(at: expectedBundlePath)
        XCTAssertEqual(files, try [
            .file(.init(path: .init(validating: "auxilary-storage.bin"))),
            .file(.init(path: .init(validating: "config.json"))),
            .file(.init(path: .init(validating: "disk.img"))),
            .file(.init(path: .init(validating: "hardware-model.bin"))),
            .file(.init(path: .init(validating: "machine-identifier.bin"))),
            .file(.init(path: .init(validating: "metadata.json"))),
        ])
        XCTAssertBundlesEqual(bundle, path: expectedBundlePath)
    }

    // MARK: - Private

    private var anyBundlePath: AbsolutePath {
        environment.fixtures.appending(component: "any-bundle")
    }

    private var anyReference: String {
        "any-reference"
    }

    private var anyTag: String {
        "1.0.0"
    }

    private func importAnyImage(reference: String) throws {
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        try subject.importImage(sourcePath: bundle.path.pathString, reference: reference)
    }
}

private extension XCTestCase {
    func XCTAssertBundlesEqual(_ bundle: Fixtures.Bundle, path: AbsolutePath) {
        do {
            try bundle.allPaths.forEach {
                if !FileManager.default.fileExists(atPath: $0.pathString),
                   !FileManager.default.fileExists(atPath: path.appending(component: $0.basename).pathString) {
                    return
                }
                try XCTAssertEqual(
                    $0.readString(),
                    path.appending(component: $0.basename).readString()
                )
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private extension AbsolutePath {
    func readString() throws -> String? {
        try String(data: Data(contentsOf: asURL), encoding: .utf8)
    }
}
