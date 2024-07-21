import CurieCommon
import Foundation

public struct ConfigInteractorContext {
    public var reference: String

    public init(
        reference: String
    ) {
        self.reference = reference
    }
}

public protocol ConfigInteractor {
    func execute(with context: ConfigInteractorContext) throws
}

public final class DefaultConfigInteractor: ConfigInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let system: System

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        system: System
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.system = system
    }

    public func execute(with context: ConfigInteractorContext) throws {
        let reference = try imageCache.findReference(context.reference)
        let bundle = try VMBundle(path: imageCache.path(to: reference))
        try system.execute(["open", "-t", bundle.config.pathString])
    }
}
