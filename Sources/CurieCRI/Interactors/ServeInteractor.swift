import Foundation

public struct ServeInteractorContext {
    public init() {}
}

public protocol ServeInteractor {
    func execute(with context: ServeInteractorContext) throws
}

final class DefaultServeInteractor: ServeInteractor {
    func execute(with _: ServeInteractorContext) throws {
        print("hello world....")
    }
}
