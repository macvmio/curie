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
import Foundation
import TSCBasic

public final class MockFileSystem: CurieCommon.FileSystem {
    public enum Call: Equatable {
        case write(data: Data, path: AbsolutePath)
    }

    public var currentWorkingDirectory: TSCBasic.AbsolutePath
    public var homeDirectory: TSCBasic.AbsolutePath

    init(currentWorkingDirectory: TSCBasic.AbsolutePath, homeDirectory: TSCBasic.AbsolutePath) {
        self.currentWorkingDirectory = currentWorkingDirectory
        self.homeDirectory = homeDirectory
    }

    public convenience init() {
        self.init(
            currentWorkingDirectory: try! AbsolutePath(validating: "/test"),
            homeDirectory: try! AbsolutePath(validating: "/Users/testuser")
        )
    }

    public private(set) var calls: [Call] = []

    public var mockRead: (AbsolutePath) throws -> Data = { _ in Data() }

    public func exists(at _: TSCBasic.AbsolutePath) -> Bool {
        fatalError("Not implemented yet")
    }

    public func move(from _: TSCBasic.AbsolutePath, to _: TSCBasic.AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func copy(from _: AbsolutePath, to _: AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func remove(at _: TSCBasic.AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func list(at _: TSCBasic.AbsolutePath) throws -> [CurieCommon.FileSystemItem] {
        fatalError("Not implemented yet")
    }

    public func createDirectory(at _: TSCBasic.AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func isExecutable(at _: TSCBasic.AbsolutePath) -> Bool {
        fatalError("Not implemented yet")
    }

    public func isFile(at _: TSCBasic.AbsolutePath) -> Bool {
        fatalError("Not implemented yet")
    }

    public func isDirectory(at _: TSCBasic.AbsolutePath) -> Bool {
        fatalError("Not implemented yet")
    }

    public func makeTemporaryDirectory() throws -> CurieCommon.TemporaryDirectory {
        fatalError("Not implemented yet")
    }

    public func absolutePath(from _: String) -> TSCBasic.AbsolutePath {
        fatalError("Not implemented yet")
    }

    public func fileSize(at _: TSCBasic.AbsolutePath) throws -> CurieCommon.MemorySize {
        fatalError("Not implemented yet")
    }

    public func directorySize(at _: TSCBasic.AbsolutePath) throws -> CurieCommon.MemorySize {
        fatalError("Not implemented yet")
    }

    public func temporaryDirectory(at _: TSCBasic.AbsolutePath?) throws -> CurieCommon.Directory {
        fatalError("Not implemented yet")
    }

    public func write(data: Data, to path: TSCBasic.AbsolutePath) throws {
        calls.append(.write(data: data, path: path))
    }

    public func read(from path: TSCBasic.AbsolutePath) throws -> Data {
        try mockRead(path)
    }
}

public final class FileSystemEnvironment {
    public let baseDirectory: TemporaryDirectory
    public let currentWorkingDirectory: AbsolutePath
    public let homeDirectory: AbsolutePath
    public let fixtures: AbsolutePath
    public let temporaryDirectory: AbsolutePath

    init(baseDirectory: TemporaryDirectory) {
        self.baseDirectory = baseDirectory
        currentWorkingDirectory = baseDirectory.path.appending(component: "currentWorkingDirectory")
        homeDirectory = baseDirectory.path.appending(component: "homeDirectory")
        fixtures = baseDirectory.path.appending(component: "fixtures")
        temporaryDirectory = baseDirectory.path.appending(component: "temp")
    }

    public static func make() throws -> FileSystemEnvironment {
        let baseDirectory = try TemporaryDirectory()
        let environment = FileSystemEnvironment(baseDirectory: baseDirectory)

        try environment.allDirectories().forEach {
            try FileManager.default.createDirectory(atPath: $0.pathString, withIntermediateDirectories: true)
        }

        return environment
    }

    // MARK: - Private

    private func allDirectories() -> [AbsolutePath] {
        [currentWorkingDirectory, homeDirectory, fixtures, temporaryDirectory]
    }
}
