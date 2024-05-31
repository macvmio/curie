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

final class DefaultFileSystem: FileSystem {
    struct Config {
        // swiftlint:disable:next nesting
        struct Overrides {
            var currentWorkingDirectory: AbsolutePath?
            var homeDirectory: AbsolutePath?
        }

        var overrides: Overrides = .init()
    }

    private let fileManager = FileManager.default
    private let config: Config

    init(config: Config = .init()) {
        self.config = config
    }

    var currentWorkingDirectory: AbsolutePath {
        // swiftlint:disable:next force_try
        try! config.overrides.currentWorkingDirectory ?? AbsolutePath(validating: fileManager.currentDirectoryPath)
    }

    var homeDirectory: AbsolutePath {
        // swiftlint:disable:next force_try
        try! config.overrides.homeDirectory ?? AbsolutePath(validating: fileManager.homeDirectoryForCurrentUser.path())
    }

    func exists(at path: AbsolutePath) -> Bool {
        fileManager.fileExists(atPath: path.pathString)
    }

    func move(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws {
        try fileManager.moveItem(at: fromPath.asURL, to: toPath.asURL)
    }

    func copy(from fromPath: AbsolutePath, to toPath: AbsolutePath) throws {
        try fileManager.copyItem(at: fromPath.asURL, to: toPath.asURL)
    }

    func remove(at path: AbsolutePath) throws {
        try fileManager.removeItem(at: path.asURL)
    }

    func list(at path: AbsolutePath) throws -> [FileSystemItem] {
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

    func createDirectory(at path: AbsolutePath) throws {
        try fileManager.createDirectory(at: path.asURL, withIntermediateDirectories: true)
    }

    func isExecutable(at path: AbsolutePath) -> Bool {
        fileManager.isExecutableFile(atPath: path.pathString)
    }

    func isFile(at path: AbsolutePath) -> Bool {
        var directory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path.pathString, isDirectory: &directory)
        return exists && !directory.boolValue
    }

    func isDirectory(at path: AbsolutePath) -> Bool {
        var directory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path.pathString, isDirectory: &directory)
        return exists && directory.boolValue
    }

    func makeTemporaryDirectory() throws -> TemporaryDirectory {
        try TemporaryDirectory()
    }

    func absolutePath(from string: String) throws -> AbsolutePath {
        string.hasPrefix("/") ? try AbsolutePath(validating: string) : currentWorkingDirectory
            .appending(RelativePath(string))
    }

    func fileSize(at path: AbsolutePath) throws -> MemorySize {
        let attributes = try fileManager.attributesOfItem(atPath: path.pathString)
        guard let size = attributes[FileAttributeKey.size] as? UInt64 else {
            throw CoreError.generic("Cannot calculate size of the file at path=\(path.pathString)")
        }
        return .init(bytes: size)
    }

    func directorySize(at path: AbsolutePath) throws -> MemorySize {
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

    func temporaryDirectory(at existingPath: AbsolutePath?) throws -> Directory {
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

    func write(data: Data, to path: AbsolutePath) throws {
        try data.write(to: path.asURL)
    }

    func read(from path: AbsolutePath) throws -> Data {
        try Data(contentsOf: path.asURL)
    }
}
