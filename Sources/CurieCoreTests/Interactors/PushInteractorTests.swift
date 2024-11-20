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

final class PushInteractorTests: XCTestCase {
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

    func testPushPluginNotAvailable() throws {
        // When
        try subject.execute(.push(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin does not exist at '\(pushExecutablePath)'")]
        )
    }

    func testPushPluginNotAFile() throws {
        // Given
        try env.fileManager.createDirectory(atPath: pushExecutablePath, withIntermediateDirectories: true)

        // When
        try subject.execute(.push(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin at '\(pushExecutablePath)' is not a file")]
        )
    }

    func testPushPluginNotExecutable() throws {
        // Given
        env.fileManager.createFile(atPath: pushExecutablePath, contents: Data("".utf8))

        // When
        try subject.execute(.push(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(
            env.console.calls,
            [.error("Plugin at '\(pushExecutablePath)' is not executable")]
        )
    }

    func testPushPluginSuccessCall() throws {
        // Given
        env.fileManager.createFile(atPath: pushExecutablePath, contents: Data("".utf8))
        try env.fileManager.markAsExecuable(atPath: pushExecutablePath)

        // When
        try subject.execute(.push(.init(reference: anyReference)))

        // Then
        XCTAssertEqual(env.console.calls, [])
        XCTAssertEqual(env.system.calls, [.execute([pushExecutablePath, "--reference", anyReference])])
    }

    // MARK: - Private

    private var anyReference: String {
        "test-reference"
    }

    private var pushExecutablePath: String {
        env.fileSystem.homeDirectory.appending(components: [".curie", "plugins", "push"]).pathString
    }
}
