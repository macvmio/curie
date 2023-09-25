import Combine
import CurieCommon
import Foundation

public struct CreateInteractorContext {
    public var reference: String
    public var name: String?

    public init(
        reference: String,
        name: String?
    ) {
        self.reference = reference
        self.name = name
    }
}

public protocol CreateInteractor {
    func execute(with context: CreateInteractorContext) throws
}

public final class DefaultCreateInteractor: CreateInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let console: Console

    private var cancellables = Set<AnyCancellable>()

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        console: Console
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.console = console
    }

    public func execute(with context: CreateInteractorContext) throws {
        let sourceReference = try imageCache.findImageReference(context.reference)
        let targetReference = try imageCache.cloneImage(source: sourceReference, target: .newReference)

        let bundle = VMBundle(path: imageCache.path(to: targetReference))
        try bundleParser.updateMetadata(bundle: bundle) { metadata in
            metadata.name = context.name
        }

        console.text(targetReference.id.description)
    }
}
