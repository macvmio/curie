import CurieCommon
import Foundation

public struct ImportInteractorContext {
    public var reference: String
    public var path: String

    public init(reference: String, path: String) {
        self.reference = reference
        self.path = path
    }
}

public protocol ImportInteractor {
    func execute(with context: ImportInteractorContext) throws
}

public final class DefaultImportInteractor: ImportInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    public func execute(with context: ImportInteractorContext) throws {
        try imageCache.importImage(sourcePath: context.path, reference: context.reference)

        console.text("Image has been imported")
    }
}
