import CurieCommon
import Foundation
import TSCBasic

protocol ImageCache {
    func makeEmptyReference(_ reference: String) throws -> ImageReference
    func findReference(_ reference: String) throws -> ImageReference
    func removeImage(_ reference: ImageReference) throws
    func cloneImage(source: ImageReference, target: String) throws
    func path(to reference: ImageReference) -> AbsolutePath
}

final class DefaultImageCache: ImageCache {
    let bundleParser: VMBundleParser
    let system: System
    let fileSystem: CurieCommon.FileSystem

    init(bundleParser: VMBundleParser, system: System, fileSystem: CurieCommon.FileSystem) {
        self.bundleParser = bundleParser
        self.system = system
        self.fileSystem = fileSystem
    }

    func makeEmptyReference(_ reference: String) throws -> ImageReference {
        let descriptor = try ImageDescriptor(reference: reference)
        let relativePath = RelativePath(reference)
        let absolutePath = rootAbsolutePath.appending(relativePath)
        guard !fileSystem.exists(at: absolutePath) else {
            throw CoreError
                .generic(
                    "Cannot create empty reference, image with given reference (<repository>:<tag>) already exists"
                )
        }
        return ImageReference(id: ImageID.make(), descriptor: descriptor)
    }

    func findReference(_ reference: String) throws -> ImageReference {
        let descriptor = try ImageDescriptor(reference: reference)
        let absolutePath = path(to: descriptor)
        guard fileSystem.exists(at: absolutePath) else {
            throw CoreError.generic("Cannot find the image")
        }
        let bundle = VMBundle(path: absolutePath)
        let state = try bundleParser.readState(from: bundle)
        return ImageReference(id: state.id, descriptor: descriptor)
    }

    func removeImage(_ reference: ImageReference) throws {
        let absolutePath = path(to: reference)
        try fileSystem.remove(at: absolutePath)
    }

    func cloneImage(source: ImageReference, target: String) throws {
        let targetDescriptor = try ImageDescriptor(reference: target)
        let targetAbsolutePath = path(to: targetDescriptor)
        let sourceAbsolutePath = path(to: source)
        guard sourceAbsolutePath != targetAbsolutePath else {
            throw CoreError.generic("Cannot clone, target reference is the same as source")
        }

        try system.execute(["cp", "-c", "-r", sourceAbsolutePath.pathString, targetAbsolutePath.pathString])

        let bundle = VMBundle(path: targetAbsolutePath)
        var state = try bundleParser.readState(from: bundle)
        state.id = ImageID.make()
        try bundleParser.writeState(state, toBundle: bundle)
    }

    func path(to reference: ImageReference) -> AbsolutePath {
        rootAbsolutePath.appending(reference.descriptor.relativePath())
    }

    func path(to descriptor: ImageDescriptor) -> AbsolutePath {
        rootAbsolutePath.appending(descriptor.relativePath())
    }

    // MARK: - Private

    private var rootAbsolutePath: AbsolutePath {
        fileSystem.homeDirectory
            .appending(component: ".curie")
            .appending(component: "images")
    }
}

private extension ImageDescriptor {
    func relativePath() -> RelativePath {
        if let tag {
            return RelativePath("\(repository):\(tag)")
        } else {
            return RelativePath(repository)
        }
    }
}
