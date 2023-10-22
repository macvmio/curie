import CurieCommon
import Foundation

public struct ExportInteractorContext {
    public var reference: String
    public var path: String
    public var compress: Bool

    public init(reference: String, path: String, compress: Bool) {
        self.reference = reference
        self.path = path
        self.compress = compress
    }
}

public protocol ExportInteractor {
    func execute(with context: ExportInteractorContext) throws
}

public final class DefaultExportInteractor: ExportInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    public func execute(with context: ExportInteractorContext) throws {
        let reference = try imageCache.findImageReference(context.reference)

        if context.compress {
            console.text("Compressing... (might take several minutes)")
        }

        try imageCache.exportImage(
            source: reference,
            destinationPath: context.path,
            mode: context.compress ? .compress : .raw
        )

        console.text("Image has been exported")
    }
}
