import CurieCommon
import Foundation

public struct RmInteractorContext {
    public var reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

public protocol RmInteractor {
    func execute(with context: RmInteractorContext) throws
}

final class DefaultRmInteractor: RmInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(with context: RmInteractorContext) throws {
        let reference = try imageCache.findContainerReference(context.reference)

        try imageCache.removeImage(reference)

        console.text("Container has been removed")
    }
}
