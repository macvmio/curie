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

final class BuildInteractorTests: XCTestCase {
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

    func testExecute_emptyReference() throws {
        // When
        let error = try XCTError(subject.execute(.build(
            .init(ipswPath: "test/path.ipsw", reference: "", diskSize: "1 GB", configPath: nil)
        )))

        // Then
        XCTAssertEqual(
            error,
            .init(
                exitCode: 1,
                message: "Cannot create empty reference, please use (<repository>[:<tag>]) format"
            )
        )
    }

    func testExecute_invalidDiskSize() throws {
        // When
        let error = try XCTError(subject.execute(.build(
            .init(ipswPath: "test/path.ipsw", reference: "reference", diskSize: "1GT", configPath: nil)
        )))

        // Then
        XCTAssertEqual(
            error,
            .init(
                exitCode: 1,
                message: "Invalid disk size",
                metadata: ["SIZE": "1GT"]
            )
        )
    }
}
