import CurieCommon
import Foundation

public struct RmiInteractorContext {
    public var reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

public protocol RmiInteractor {
    func execute(with context: RmiInteractorContext) throws
}

final class DefaultRmiInteractor: RmiInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(with context: RmiInteractorContext) throws {
        let reference = try imageCache.findImageReference(context.reference)

        try imageCache.removeImage(reference)

        console.text("Image has been removed")
    }
}
