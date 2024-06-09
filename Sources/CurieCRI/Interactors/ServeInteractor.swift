import Foundation

public struct ServeInteractorContext {
    public init() {}
}

public protocol ServeInteractor {
    func execute(with context: ServeInteractorContext) throws
}

final class DefaultServeInteractor: ServeInteractor {
    private let server: CRIServer

    init(server: CRIServer) {
        self.server = server
    }

    func execute(with context: ServeInteractorContext) throws {
        try server.start(config: .init())
    }
}
