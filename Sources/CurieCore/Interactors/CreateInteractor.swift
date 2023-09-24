import Combine
import CurieCommon
import Foundation
import TSCBasic
import Virtualization

public struct CreateInteractorContext {
    public var reference: String

    public init(
        reference: String
    ) {
        self.reference = reference
    }
}

public protocol CreateInteractor {
    func execute(with context: CreateInteractorContext) throws
}

public final class DefaultCreateInteractor: CreateInteractor {
    private let imageCache: ImageCache
    private let console: Console

    private var cancellables = Set<AnyCancellable>()

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    public func execute(with context: CreateInteractorContext) throws {
        let sourceReference = try imageCache.findImageReference(context.reference)
        let targetReference = try imageCache.cloneImage(source: sourceReference, target: .ephemeral)

        console.text(targetReference.id.description)
    }
}
