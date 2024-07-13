import Combine
import CurieCommon
import Foundation
import TSCBasic
import Virtualization

public struct StartInteractorContext {
    public var reference: String
    public var launch: LaunchParameters

    public init(reference: String, launch: LaunchParameters) {
        self.reference = reference
        self.launch = launch
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
        console.setQuiet(context.launch.quiet)
        console.text("Start \(context.reference) container")

        let sourceReference = try imageCache.findContainerReference(context.reference)

        let bundle = VMBundle(path: imageCache.path(to: sourceReference))
        let overrideConfig = try context.launch.partialConfig()
        let vm = try configurator.loadVM(with: bundle, overrideConfig: overrideConfig)
        let options = VMStartOptions(
            startUpFromMacOSRecovery: context.launch.recoveryMode,
            noWindow: context.launch.noWindow,
            quiet: context.launch.quiet
        )

        try imageRunner.run(vm: vm, bundle: bundle, options: options)
    }
}
