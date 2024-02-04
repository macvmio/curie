@testable import CurieCommon
import CurieCommonMocks
@testable import CurieCore
import Foundation
import XCTest

final class ImageCacheTests: XCTestCase {
    private var subject: DefaultImageCache!
    private var fileSystem: FileSystem!
    private var bundleParser: VMBundleParser!
    private var wallClock: MockWallClock!
    private var system: System!

    private var environment: FileSystemEnvironment!

    override func setUpWithError() throws {
        super.setUp()
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
        XCTAssertThrowsError(try subject.findImageReference(anyReference)) { error in
            let coreError = error as? CoreError
            XCTAssertEqual(coreError?.localizedDescription, "Cannot find the image")
        }
    }

    // MARK: - Private

    private var anyReference: String {
        "any-reference"
    }

    private var anyTag: String {
        "1.0.0"
    }
}
