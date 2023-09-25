import Combine
import CurieCommon
import Foundation

public struct CommitInteractorContext {
    public var containerReference: String
    public var imageReference: String?

    public init(containerReference: String, imageReference: String?) {
        self.containerReference = containerReference
        self.imageReference = imageReference
    }
}

public protocol CommitInteractor {
    func execute(with context: CommitInteractorContext) throws
}

public final class DefaultCommitInteractor: CommitInteractor {
    private let configurator: VMConfigurator
    private let imageCache: ImageCache
    private let console: Console

    private var cancellables = Set<AnyCancellable>()

    init(
        configurator: VMConfigurator,
        imageCache: ImageCache,
        console: Console
    ) {
        self.configurator = configurator
        self.imageCache = imageCache
        self.console = console
    }

    public func execute(with context: CommitInteractorContext) throws {
        let sourceReference = try imageCache.findContainerReference(context.containerReference)
        let targetReference = try context.imageReference.map { try ImageReference(
            id: sourceReference.id,
            descriptor: .init(reference: $0),
            type: .image
        ) } ?? sourceReference.asImageReference()

        let bundle = VMBundle(path: imageCache.path(to: targetReference))
        let vm = try configurator.loadVM(with: bundle)

        guard vm.virtualMachine.state == .stopped || vm.virtualMachine.state == .paused else {
            throw CoreError.generic("Cammit failed, container is not stopped or paused")
        }

        try imageCache.moveImage(source: sourceReference, target: targetReference)

        console.text("Image \(targetReference.id.description) has been saved")
    }
}

private extension ImageReference {
    func asImageReference() -> ImageReference {
        ImageReference(
            id: id,
            descriptor: .init(repository: String(descriptor.repository.dropFirst(14)), tag: descriptor.tag),
            type: .image
        )
    }
}
