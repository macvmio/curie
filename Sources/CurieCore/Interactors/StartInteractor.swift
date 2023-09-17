import Combine
import CurieCommon
import Foundation
import TSCBasic
import Virtualization

public struct StartInteractorContext {
    public var reference: String
    public var noWindow: Bool

    public init(
        reference: String,
        noWindow: Bool
    ) {
        self.reference = reference
        self.noWindow = noWindow
    }
}

public protocol StartInteractor {
    func execute(with context: StartInteractorContext) throws
}

public final class DefaultStartInteractor: StartInteractor {
    private let configurator: VMConfigurator
    private let imageRunner: ImageRunner
    private let imageCache: ImageCache
    private let system: System
    private let console: Console
    private var cancellables = Set<AnyCancellable>()

    init(
        configurator: VMConfigurator,
        imageRunner: ImageRunner,
        imageCache: ImageCache,
        system: System,
        console: Console
    ) {
        self.configurator = configurator
        self.imageRunner = imageRunner
        self.imageCache = imageCache
        self.system = system
        self.console = console
    }

    public func execute(with context: StartInteractorContext) throws {
        console.text("Start image \(context.reference)")

        let sourceReference = try imageCache.findImageReference(context.reference)
        let targetReference = try imageCache.cloneImage(source: sourceReference, target: .ephemeral)

        let bundle = VMBundle(path: imageCache.path(to: targetReference))
        let vm = try configurator.loadVM(with: bundle)

        vm.events
            .filter { $0 == .imageDidStop || $0 == .imageStopFailed }
            .sink { [imageCache, console] _ in
                do {
                    try imageCache.moveImage(source: targetReference, target: sourceReference)
                } catch {
                    console.error(error.localizedDescription)
                }
            }
            .store(in: &cancellables)

        try imageRunner.run(vm: vm, bundle: bundle, noWindow: context.noWindow)
    }
}
