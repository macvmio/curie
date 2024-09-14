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

enum Target {
    case reference(String)
    case newReference
}

enum ExportMode {
    case raw
    case compress
}

struct ImageItem: Equatable {
    var reference: ImageReference
    var createAt: Date
    var size: MemorySize
    var name: String?
}

protocol ImageCache {
    func makeImageReference(_ reference: String) throws -> ImageReference
    func findReference(_ reference: String) throws -> ImageReference
    func findImageReference(_ reference: String) throws -> ImageReference
    func findContainerReference(_ reference: String) throws -> ImageReference
    func listImages() throws -> [ImageItem]
    func listContainers() throws -> [ImageItem]
    func removeImage(_ reference: ImageReference) throws

    @discardableResult
    func cloneImage(source: ImageReference, target: Target) throws -> ImageReference
    func moveImage(source: ImageReference, target: ImageReference) throws
    func path(to reference: ImageReference) -> AbsolutePath
    func bundle(for reference: ImageReference) -> VMBundle

    func exportImage(source: ImageReference, destinationPath: String, mode: ExportMode) throws
    func importImage(sourcePath: String, reference: String) throws
}

// swiftlint:disable:next type_body_length
final class DefaultImageCache: ImageCache {
    let bundleParser: VMBundleParser
    let wallClock: WallClock
    let system: System
    let fileSystem: CurieCommon.FileSystem

    init(
        bundleParser: VMBundleParser,
        wallClock: WallClock,
        system: System,
        fileSystem: CurieCommon.FileSystem
    ) {
        self.bundleParser = bundleParser
        self.wallClock = wallClock
        self.system = system
        self.fileSystem = fileSystem
    }

    func makeImageReference(_ reference: String) throws -> ImageReference {
        guard !reference.isEmpty else {
            throw CoreError
                .generic("Cannot create empty reference, please use (\(CurieCore.Constants.referenceFormat)) format")
        }
        let descriptor = try ImageDescriptor(reference: reference)
        let relativePath = RelativePath(reference)
        let absolutePath = imagesAbsolutePath().appending(relativePath)
        guard !fileSystem.exists(at: absolutePath) else {
            throw CoreError
                .generic(
                    "Cannot create empty reference, image with given reference (\(CurieCore.Constants.referenceFormat))"
                        + " already exists"
                )
        }
        return ImageReference(id: ImageID.make(), descriptor: descriptor, type: .image)
    }

    func findReference(_ reference: String) throws -> ImageReference {
        if let reference = try? findImageReference(reference) {
            return reference
        }
        return try findContainerReference(reference)
    }

    func findImageReference(_ reference: String) throws -> ImageReference {
        try findReference(reference, type: .image)
    }

    func findContainerReference(_ reference: String) throws -> ImageReference {
        try findReference(reference, type: .container)
    }

    func listImages() throws -> [ImageItem] {
        let references = try listImages(at: imagesAbsolutePath(), basePath: imagesAbsolutePath(), type: .image)
        return try items(from: references)
    }

    func listContainers() throws -> [ImageItem] {
        let references = try listImages(
            at: containersAbsolutePath(),
            basePath: containersAbsolutePath(),
            type: .container
        )
        return try items(from: references)
    }

    func removeImage(_ reference: ImageReference) throws {
        let absolutePath = path(to: reference)
        try fileSystem.remove(at: absolutePath)
        try removeEmptySubdirectories(of: imagesAbsolutePath())
        try removeEmptySubdirectories(of: containersAbsolutePath())
    }

    @discardableResult
    func cloneImage(source: ImageReference, target: Target) throws -> ImageReference {
        let sourceAbsolutePath = path(to: source)
        let targetId = ImageID.make()
        let targetDescriptor = try target.imageDescriptor(source: source, imageId: targetId)
        let targetReference = ImageReference(id: targetId, descriptor: targetDescriptor, type: target.imageType())
        let targetAbsolutePath = path(to: targetReference)
        guard sourceAbsolutePath != targetAbsolutePath else {
            throw CoreError.generic("Cannot clone, target reference is the same as source")
        }
        try fileSystem.createDirectory(at: targetAbsolutePath.parentDirectory)
        try fileSystem.copy(from: sourceAbsolutePath, to: targetAbsolutePath)

        let bundle = VMBundle(path: targetAbsolutePath)
        try bundleParser.updateMetadata(bundle: bundle) { metadata in
            metadata.id = targetId
            metadata.createdAt = wallClock.now()
        }

        return targetReference
    }

    func moveImage(source: ImageReference, target: ImageReference) throws {
        let sourceAbsolutePath = path(to: source)
        let targetAbsolutePath = path(to: target)

        if fileSystem.exists(at: targetAbsolutePath) {
            try fileSystem.remove(at: targetAbsolutePath)
        }

        if !fileSystem.exists(at: targetAbsolutePath.parentDirectory) {
            try fileSystem.createDirectory(at: targetAbsolutePath.parentDirectory)
        }

        try fileSystem.move(from: sourceAbsolutePath, to: targetAbsolutePath)

        try removeEmptySubdirectories(of: containersAbsolutePath())
    }

    func path(to reference: ImageReference) -> AbsolutePath {
        storeAbsolutePath(reference.type).appending(reference.descriptor.relativePath())
    }

    func bundle(for reference: ImageReference) -> VMBundle {
        VMBundle(path: path(to: reference))
    }

    func exportImage(source: ImageReference, destinationPath: String, mode: ExportMode) throws {
        let sourceAbsolutePath = path(to: source)
        let targetAbsolutePath = fileSystem.absolutePath(from: destinationPath)
        if fileSystem.exists(at: targetAbsolutePath) {
            guard try fileSystem.list(at: targetAbsolutePath).isEmpty else {
                throw CoreError.generic("Failed to export image, directory at \(targetAbsolutePath) isn't empty")
            }
        }

        if !fileSystem.exists(at: targetAbsolutePath.parentDirectory) {
            try fileSystem.createDirectory(at: targetAbsolutePath.parentDirectory)
        }

        switch mode {
        case .raw:
            try fileSystem.copy(from: sourceAbsolutePath, to: targetAbsolutePath)
        case .compress:
            try system.execute(
                ["zip", "-rjq", targetAbsolutePath.pathString, sourceAbsolutePath.pathString, "-x", ".DS_Store"]
            )
        }
    }

    func importImage(sourcePath: String, reference: String) throws {
        defer {
            _ = try? removeEmptySubdirectories(of: imagesAbsolutePath())
        }

        let sourceAbsolutePath = fileSystem.absolutePath(from: sourcePath)

        guard fileSystem.exists(at: sourceAbsolutePath) else {
            throw CoreError.generic("Failed to import image, exported image at \(sourcePath) does not exist")
        }

        let targetReference = try makeImageReference(reference)
        let targetAbsolutePath = path(to: targetReference)

        try fileSystem.createDirectory(at: targetAbsolutePath.parentDirectory)

        let sourceImageAbsolutePath: AbsolutePath
        let temporaryDirectory = try fileSystem.makeTemporaryDirectory()

        if fileSystem.isFile(at: sourceAbsolutePath) {
            try system.execute(
                ["unzip", "-q", sourceAbsolutePath.pathString, "-d", temporaryDirectory.path.pathString]
            )
            sourceImageAbsolutePath = temporaryDirectory.path
        } else {
            sourceImageAbsolutePath = sourceAbsolutePath
        }

        let bundle = VMBundle(path: sourceImageAbsolutePath)
        let metadata = try bundleParser.readMetadata(from: bundle)
        let existingImage = try listImages().first { $0.reference.id == metadata.id }
        guard existingImage == nil else {
            throw CoreError
                .generic("Failed to import image, image with \(metadata.id) identifier already exists")
        }

        try fileSystem.copy(from: sourceImageAbsolutePath, to: targetAbsolutePath)
    }

    // MARK: - Private

    private func items(from references: [ImageReference]) throws -> [ImageItem] {
        let items = try references.map {
            let bundle = bundle(for: $0)
            let metadata = try bundleParser.readMetadata(from: bundle)
            return try ImageItem(
                reference: $0,
                createAt: metadata.createdAt,
                size: fileSystem.directorySize(at: path(to: $0)),
                name: metadata.name
            )
        }
        .sorted { $0.reference.id < $1.reference.id }
        return items
    }

    private func storeAbsolutePath(_ type: ImageType) -> AbsolutePath {
        switch type {
        case .container:
            containersAbsolutePath()
        case .image:
            imagesAbsolutePath()
        }
    }

    private func imagesAbsolutePath() -> AbsolutePath {
        dataRootDirectory().appending(component: "images")
    }

    private func containersAbsolutePath() -> AbsolutePath {
        dataRootDirectory().appending(component: "containers")
    }

    private func findReference(_ reference: String, type: ImageType) throws -> ImageReference {
        let descriptor = try ImageDescriptor(reference: reference)
        let absolutePath = storeAbsolutePath(type).appending(descriptor.relativePath())
        guard fileSystem.exists(at: absolutePath) else {
            switch type {
            case .container:
                guard let image = try listContainers().first(where: { $0.reference.id.description == reference }) else {
                    throw CoreError.generic("Cannot find the container")
                }
                return image.reference
            case .image:
                guard let image = try listImages().first(where: { $0.reference.id.description == reference }) else {
                    throw CoreError.generic("Cannot find the image")
                }
                return image.reference
            }
        }
        let bundle = VMBundle(path: absolutePath)
        let metadata = try bundleParser.readMetadata(from: bundle)
        return ImageReference(id: metadata.id, descriptor: descriptor, type: type)
    }

    private func listImages(at path: AbsolutePath, basePath: AbsolutePath, type: ImageType) throws -> [ImageReference] {
        var result: [ImageReference] = []

        guard fileSystem.exists(at: path) else {
            return []
        }

        let list = try fileSystem.list(at: path)

        let directories = Set(list.compactMap {
            if case let .directory(directory) = $0 {
                return path.appending(directory.path)
            }
            return nil
        })

        let images = Set(directories.filter { bundleParser.canParseConfig(at: VMBundle(path: $0).config) })
        let paths = images.map { $0.relative(to: basePath) }
        let references = try paths.map { try findReference($0.pathString, type: type) }

        result.append(contentsOf: references)

        let subdirectories = directories.subtracting(images)

        try subdirectories.forEach {
            let references = try listImages(at: $0, basePath: basePath, type: type)
            result.append(contentsOf: references)
        }

        return result
    }

    @discardableResult
    private func removeEmptySubdirectories(of path: AbsolutePath) throws -> Bool {
        guard fileSystem.exists(at: path) else {
            return true
        }

        let list = try fileSystem.list(at: path)

        let directories = list.compactMap {
            if case let .directory(directory) = $0 {
                return path.appending(directory.path)
            }
            return nil
        }

        var empty = true
        try directories.forEach { path in
            empty = try empty && removeEmptySubdirectories(of: path)
        }

        let files = list.compactMap {
            if case let .file(file) = $0 {
                return file
            }
            return nil
        }

        guard files.isEmpty, empty else {
            return false
        }

        try fileSystem.remove(at: path)

        return true
    }

    private func dataRootDirectory() -> AbsolutePath {
        if let overrideDataRootString = system.environmentVariable(name: Constants.dataRootEnvironmentVariable) {
            return fileSystem.absolutePath(from: overrideDataRootString)
        }
        return fileSystem.homeDirectory.appending(component: ".curie")
    }
}

private extension ImageDescriptor {
    func relativePath() -> RelativePath {
        if let tag {
            RelativePath("\(repository):\(tag)")
        } else {
            RelativePath(repository)
        }
    }
}

private extension Target {
    func imageDescriptor(source: ImageReference, imageId: ImageID) throws -> ImageDescriptor {
        switch self {
        case let .reference(reference):
            try ImageDescriptor(reference: reference)
        case .newReference:
            ImageDescriptor(
                repository: "@\(imageId.description)/\(source.descriptor.repository)",
                tag: source.descriptor.tag
            )
        }
    }

    func imageType() -> ImageType {
        switch self {
        case .reference:
            .image
        case .newReference:
            .container
        }
    }
}
