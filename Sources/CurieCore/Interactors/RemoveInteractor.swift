import CurieCommon
import Foundation

public struct RemoveInteractorContext {
    public var reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

public protocol RemoveInteractor {
    func execute(with context: RemoveInteractorContext) throws
}

final class DefaultRemoveInteractor: RemoveInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(with context: RemoveInteractorContext) throws {
        let reference = try imageCache.findReference(context.reference)

        try imageCache.removeImage(reference)

        console.text("Image has been removed")
    }
}
