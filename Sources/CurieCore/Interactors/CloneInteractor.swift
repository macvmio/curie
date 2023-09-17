import CurieCommon
import Foundation

public struct CloneInteractorContext {
    public var sourceReference: String
    public var targetReference: String

    public init(sourceReference: String, targetReference: String) {
        self.sourceReference = sourceReference
        self.targetReference = targetReference
    }
}

public protocol CloneInteractor {
    func execute(with context: CloneInteractorContext) throws
}

final class DefaultCloneInteractor: CloneInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(with context: CloneInteractorContext) throws {
        let source = try imageCache.findImageReference(context.sourceReference)

        try imageCache.cloneImage(source: source, target: .reference(context.targetReference))

        console.text("Image has been cloned")
    }
}
