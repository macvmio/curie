import CurieCommon
import Foundation
import TSCBasic

protocol ImageCache {
    func makeEmptyRef(reference: String) throws -> ImageReference
    func path(to reference: ImageReference) -> AbsolutePath
}

final class DefaultImageCache: ImageCache {
    let system: System
    let fileSystem: CurieCommon.FileSystem

    init(system: System, fileSystem: CurieCommon.FileSystem) {
        self.system = system
        self.fileSystem = fileSystem
    }

    func makeEmptyRef(reference: String) throws -> ImageReference {
        let descriptor = try ImageDescriptor(reference: reference)
        let relativePath = RelativePath(reference)
        let absolutePath = rootAbsolutePath.appending(relativePath)
        guard !fileSystem.exists(at: absolutePath) else {
            throw CoreError.generic("Cannot create empty ref, image with given reference (<repository>:<tag>) already exists")
        }
        return ImageReference(id: ImageID.make(), desciptor: descriptor)
    }

    func path(to ref: ImageReference) -> AbsolutePath {
        rootAbsolutePath.appending(ref.relativePath())
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
