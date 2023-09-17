import CurieCommon
import Foundation

enum ImageType {
    case ephemeral
    case persistent
}

struct ImageDescriptor: Equatable {
    let repository: String
    let tag: String?

    init(repository: String, tag: String?) {
        self.repository = repository
        self.tag = tag
    }

    init(reference: String) throws {
        let split = reference.split(separator: ":")
        if split.count == 1 {
            self = .init(repository: String(split[0]), tag: nil)
            return
        }
        if split.count == 2 {
            self = .init(repository: String(split[0]), tag: String(split[1]))
            return
        }
        throw CoreError.generic("Invalid reference '\(reference)'")
    }
}

struct ImageReference: Equatable {
    let id: ImageID
    let descriptor: ImageDescriptor
    let type: ImageType
}
