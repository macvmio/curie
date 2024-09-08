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

import Foundation
import TSCBasic

public enum FileSystemItem: Hashable {
    public struct File: Hashable {
        public let path: RelativePath
    }

    public struct Directory: Hashable {
        public let path: RelativePath
    }

    case file(File)
    case directory(Directory)
}

public protocol FileSystem {
    var currentWorkingDirectory: AbsolutePath { get }

    var homeDirectory: AbsolutePath { get }

    func exists(at path: AbsolutePath) -> Bool

    func move(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws

    func copy(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws

    func remove(at path: AbsolutePath) throws

    func list(at path: AbsolutePath) throws -> [FileSystemItem]

    func createDirectory(at path: AbsolutePath) throws

    func isExecutable(at path: AbsolutePath) -> Bool

    func isFile(at path: AbsolutePath) -> Bool

    func isDirectory(at path: AbsolutePath) -> Bool

    func makeTemporaryDirectory() throws -> TemporaryDirectory

    func absolutePath(from string: String) throws -> AbsolutePath

    func fileSize(at path: AbsolutePath) throws -> MemorySize

    func directorySize(at path: AbsolutePath) throws -> MemorySize

    func temporaryDirectory(at existingPath: AbsolutePath?) throws -> Directory

    func write(data: Data, to path: AbsolutePath) throws

    func read(from path: AbsolutePath) throws -> Data
}

public final class DefaultFileSystem: FileSystem {
    public struct Config {
        // swiftlint:disable:next nesting
        public struct Overrides {
            var currentWorkingDirectory: AbsolutePath?
            var homeDirectory: AbsolutePath?
        }

        var overrides: Overrides = .init()

        public init() {}

        public init(overrides: Overrides) {
            self.overrides = overrides
        }
    }

    private let fileManager = FileManager.default
    private let config: Config

    public init(config: Config = .init()) {
        self.config = config
    }

    public var currentWorkingDirectory: AbsolutePath {
        // swiftlint:disable:next force_try
        try! config.overrides.currentWorkingDirectory ?? AbsolutePath(validating: fileManager.currentDirectoryPath)
    }

    public var homeDirectory: AbsolutePath {
        // swiftlint:disable:next force_try
        try! config.overrides.homeDirectory ?? AbsolutePath(validating: fileManager.homeDirectoryForCurrentUser.path())
    }

    public func exists(at path: AbsolutePath) -> Bool {
        fileManager.fileExists(atPath: path.pathString)
    }

    public func move(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws {
        try fileManager.moveItem(at: fromPath.asURL, to: toPath.asURL)
    }

    public func copy(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws {
        try fileManager.copyItem(at: fromPath.asURL, to: toPath.asURL)
    }

    public func remove(at path: AbsolutePath) throws {
        try fileManager.removeItem(at: path.asURL)
    }

    public func list(at path: AbsolutePath) throws -> [FileSystemItem] {
        try fileManager.contentsOfDirectory(atPath: path.pathString)
            .sorted()
            .map { RelativePath($0) }
            .map {
                let absolutePath = path.appending($0)
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: absolutePath.pathString, isDirectory: &isDir)
                if isDir.boolValue {
                    return .directory(FileSystemItem.Directory(path: $0))
                } else {
                    return .file(FileSystemItem.File(path: $0))
                }
            }
    }

    public func createDirectory(at path: AbsolutePath) throws {
        try fileManager.createDirectory(at: path.asURL, withIntermediateDirectories: true)
    }

    public func isExecutable(at path: AbsolutePath) -> Bool {
        fileManager.isExecutableFile(atPath: path.pathString)
    }

    public func isFile(at path: AbsolutePath) -> Bool {
        var directory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path.pathString, isDirectory: &directory)
        return exists && !directory.boolValue
    }

    public func isDirectory(at path: AbsolutePath) -> Bool {
        var directory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path.pathString, isDirectory: &directory)
        return exists && directory.boolValue
    }

    public func makeTemporaryDirectory() throws -> TemporaryDirectory {
        try TemporaryDirectory()
    }

    public func absolutePath(from string: String) throws -> AbsolutePath {
        string.hasPrefix("/") ? try AbsolutePath(validating: string) : currentWorkingDirectory
            .appending(RelativePath(string))
    }

    public func fileSize(at path: AbsolutePath) throws -> MemorySize {
        let attributes = try fileManager.attributesOfItem(atPath: path.pathString)
        guard let size = attributes[FileAttributeKey.size] as? UInt64 else {
            throw CoreError.generic("Cannot calculate size of the file at path=\(path.pathString)")
        }
        return .init(bytes: size)
    }

    public func directorySize(at path: AbsolutePath) throws -> MemorySize {
        guard let enumerator = fileManager.enumerator(at: path.asURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            throw CoreError.generic("Cannot enumerate files at path=\(path.pathString)")
        }

        return try .init(
            bytes: enumerator
                .compactMap { $0 as? URL }
                .compactMap { try $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
                .map { UInt64($0) }
                .reduce(UInt64(), +)
        )
    }

    public func temporaryDirectory(at existingPath: AbsolutePath?) throws -> Directory {
        if let existingPath {
            let items = try list(at: existingPath)
            guard items.isEmpty else {
                throw CoreError.generic("Temporary directory is not empty (path=\(existingPath.pathString))")
            }
            return PredefinedDirectory(path: existingPath)
        } else {
            return try makeTemporaryDirectory()
        }
    }

    public func write(data: Data, to path: AbsolutePath) throws {
        try data.write(to: path.asURL)
    }

    public func read(from path: AbsolutePath) throws -> Data {
        try Data(contentsOf: path.asURL)
    }
}
