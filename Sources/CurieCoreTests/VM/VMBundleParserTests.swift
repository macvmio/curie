import CurieCommonMocks
@testable import CurieCore
import TSCBasic
import XCTest

final class DefaultVMBundleParserTests: XCTestCase {
    private var subject: DefaultVMBundleParser!
    private var fileSystem: MockFileSystem!

    override func setUp() {
        super.setUp()
        fileSystem = MockFileSystem()
        subject = DefaultVMBundleParser(fileSystem: fileSystem)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testReadConfig() throws {
        // Given
        fileSystem.mockRead = { _ in
            """
            {
              "cpuCount" : 8,
              "network" : {
                "devices" : [
                  {
                    "mode" : "NAT",
                    "macAddress" : "automatic"
                  }
                ]
              },
              "display" : {
                "width" : 640,
                "pixelsPerInch" : 100,
                "height" : 480
              },
              "memorySize" : {
                "bytes" : 1073741824
              }
            }
            """.data(using: .utf8)!
        }

        // When
        let config = try subject.readConfig(from: .init(path: anyPath))

        // Then
        XCTAssertEqual(config, .init(
            cpuCount: 8,
            memorySize: .init(bytes: 1024 * 1024 * 1024),
            display: .init(width: 640, height: 480, pixelsPerInch: 100),
            network: .init(devices: [.init(macAddress: .automatic, mode: .NAT)]),
            sharedDirectory: .init(directories: []),
            shutdown: .init(behaviour: .exit)
        ))
    }

    // MARK: - Private

    private var anyPath: AbsolutePath {
        try! AbsolutePath(validating: "/path/test")
    }
}
