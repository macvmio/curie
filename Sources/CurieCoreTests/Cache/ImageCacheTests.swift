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
    private var system: System!

    private var fixtures: Fixtures!
    private var environment: FileSystemEnvironment!

    override func setUpWithError() throws {
        super.setUp()
        fixtures = Fixtures()
        environment = try FileSystemEnvironment.make()
        wallClock = MockWallClock()
        fileSystem = DefaultFileSystem(config: .init(overrides: .init(
            currentWorkingDirectory: environment.currentWorkingDirectory,
            homeDirectory: environment.homeDirectory
        )))
        bundleParser = DefaultVMBundleParser(fileSystem: fileSystem)
        system = DefaultSystem()
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

    func test_makeImageReference_onlyRepository() throws {
        // When
        let result = try subject.makeImageReference(anyReference)

        // Then
        XCTAssertEqual(result.id.description.count, 12)
        XCTAssertEqual(result.descriptor, .init(repository: anyReference, tag: nil))
        XCTAssertEqual(result.type, .image)
    }

    func test_makeImageReference_repositoryAndTag() throws {
        // When
        let result = try subject.makeImageReference("\(anyReference):\(anyTag)")

        // Then
        XCTAssertEqual(result.id.description.count, 12)
        XCTAssertEqual(result.descriptor, .init(repository: anyReference, tag: anyTag))
        XCTAssertEqual(result.type, .image)
    }

    func test_findReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the container")
        }
    }

    func test_findContainerReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findContainerReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the container")
        }
    }

    func test_findImageReference_notFound() throws {
        // When / Then
        XCTAssertThrowsError(try subject.findImageReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the image")
        }
    }

    func test_listImages_noImages() throws {
        // When / Then
        XCTAssertEqual(try subject.listImages(), [])
    }

    func test_listContainers_noContainers() throws {
        // When / Then
        XCTAssertEqual(try subject.listContainers(), [])
    }

    func test_importImage() throws {
        // Given
        let bundle = try fixtures.makeImageBundle(at: anyBundlePath)
        let expectedBundlePath = environment.homeDirectory.appending(RelativePath(".curie/images/\(anyReference)"))

        // When
        try subject.importImage(sourcePath: bundle.path.pathString, reference: anyReference)

        // Then
        let files = try fileSystem.list(at: expectedBundlePath)
        XCTAssertEqual(files, [
            .file(.init(path: .init("auxilary-storage.bin"))),
            .file(.init(path: .init("config.json"))),
            .file(.init(path: .init("disk.img"))),
            .file(.init(path: .init("hardware-model.bin"))),
            .file(.init(path: .init("machine-identifier.bin"))),
            .file(.init(path: .init("metadata.json"))),
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
