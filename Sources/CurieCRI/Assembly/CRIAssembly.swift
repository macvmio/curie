import CurieCommon
import Foundation

public final class CRIAssembly: Assembly {
    public init() {}

    public func assemble(_ registry: Registry) {
        assembleInteractors(registry)
        assembleUtils(registry)
    }

    // MARK: - Private

    private func assembleInteractors(_ registry: Registry) {
        registry.register(ServeInteractor.self) { _ in
            DefaultServeInteractor()
        }
    }

    private func assembleUtils(_ registry: Registry) {
        registry.register(CRIServer.self) { _ in
            DefaultCRIServer()
        }
    }
}
