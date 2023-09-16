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

    public func remove(at _: TSCBasic.AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func list(at _: TSCBasic.AbsolutePath) throws -> [CurieCommon.FileSystemItem] {
        fatalError("Not implemented yet")
    }

    public func createDirectory(at _: TSCBasic.AbsolutePath) throws {
        fatalError("Not implemented yet")
    }

    public func executable(at _: TSCBasic.AbsolutePath) -> Bool {
        fatalError("Not implemented yet")
    }

    public func makeTemporaryDirectory() throws -> CurieCommon.TemporaryDirectory {
        fatalError("Not implemented yet")
    }

    public func absolutePath(from _: String) throws -> TSCBasic.AbsolutePath {
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
