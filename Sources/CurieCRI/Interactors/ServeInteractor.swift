import Foundation

public struct ServeInteractorContext {
    public let host: String
    public let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
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
        try server.start(
            config: .init(
                host: context.host,
                port: context.port
            )
        )
    }
}
