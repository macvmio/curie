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
            Data("""
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
            """.utf8)
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
            shutdown: .init(behaviour: .stop),
            clipboard: .init(enabled: false)
        ))
    }

    // MARK: - Private

    private var anyPath: AbsolutePath {
        try! AbsolutePath(validating: "/path/test")
    }
}
