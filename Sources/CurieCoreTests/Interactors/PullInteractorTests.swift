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
@testable import CurieCore
import CurieCoreMocks
import Foundation
import SCInject
import XCTest

final class PullInteractorTests: XCTestCase {
    private var subject: Interactor!
    private var env: InteractorsTestsEnvironment!

    override func setUpWithError() throws {
        super.setUp()
        env = InteractorsTestsEnvironment()
        subject = env.resolveInteractor()
    }

    override func tearDown() {
        super.tearDown()
        env = nil
        subject = nil
    }

    func testPullPluginNotAvailable() throws {
        // When
        try subject.execute(.pull(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin does not exist at '\(pullExecutablePath)'")]
        )
    }

    func testPullPluginNotAFile() throws {
        // Given
        try env.fileManager.createDirectory(atPath: pullExecutablePath, withIntermediateDirectories: true)

        // When
        try subject.execute(.pull(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin at '\(pullExecutablePath)' is not a file")]
        )
    }

    func testPullPluginNotExecutable() throws {
        // Given
        env.fileManager.createFile(atPath: pullExecutablePath, contents: Data("".utf8))

        // When
        try subject.execute(.pull(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin at '\(pullExecutablePath)' is not executable")]
        )
    }

    func testPullPluginSuccessCall() throws {
        // Given
        env.fileManager.createFile(atPath: pullExecutablePath, contents: Data("".utf8))
        try env.fileManager.markAsExecuable(atPath: pullExecutablePath)

        // When
        try subject.execute(.pull(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(env.console.calls, [])
        XCTAssertEqual(env.system.calls, [.execute([pullExecutablePath, "--reference", anyReference])])
    }

    // MARK: - Private

    private var anyReference: String {
        "test-reference"
    }

    private var pullExecutablePath: String {
        env.fileSystem.homeDirectory.appending(components: [".curie", "plugins", "pull"]).pathString
    }
}
