import CurieCommon
import Foundation

enum ImageType {
    case container
    case image
}

struct ImageDescriptor: Equatable {
    let repository: String
    let tag: String?

    init(repository: String, tag: String?) {
        self.repository = repository
        self.tag = tag
    }

    init(reference: String) throws {
        if let index = reference.lastIndex(of: ":") {
            let repository = String(reference.prefix(upTo: index))
            let tag = String(reference.suffix(from: reference.index(after: index)))
            self = .init(repository: repository, tag: !tag.isEmpty ? tag : nil)
        } else {
            self = .init(repository: reference, tag: nil)
        }
    }
}

struct ImageReference: Equatable {
    let id: ImageID
    let descriptor: ImageDescriptor
    let type: ImageType
}
