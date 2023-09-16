import CurieCommon
import Foundation
import TSCBasic

protocol ImageCache {
    func makeEmptyReference(_ reference: String) throws -> ImageReference
    func findReference(_ reference: String) throws -> ImageReference
    func removeImage(_ reference: ImageReference) throws
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
        return ImageReference(id: ImageID.make(), desciptor: descriptor)
    }

    func findReference(_ reference: String) throws -> ImageReference {
        let descriptor = try ImageDescriptor(reference: reference)
        let relativePath = RelativePath(reference)
        let absolutePath = rootAbsolutePath.appending(relativePath)
        guard fileSystem.exists(at: absolutePath) else {
            throw CoreError.generic("Cannot find the image")
        }
        let bundle = VMBundle(path: absolutePath)
        let state = try bundleParser.readState(from: bundle)
        return ImageReference(id: state.id, desciptor: descriptor)
    }

    func removeImage(_ reference: ImageReference) throws {
        let absolutePath = path(to: reference)
        try fileSystem.remove(at: absolutePath)
    }

    func path(to reference: ImageReference) -> AbsolutePath {
        rootAbsolutePath.appending(reference.relativePath())
    }

    // MARK: - Private

    private var rootAbsolutePath: AbsolutePath {
        fileSystem.homeDirectory
            .appending(component: ".curie")
            .appending(component: "images")
    }
}

private extension ImageReference {
    func relativePath() -> RelativePath {
        if let tag = desciptor.tag {
            return RelativePath("\(desciptor.repository):\(tag)")
        } else {
            return RelativePath(desciptor.repository)
        }
    }
}
