import CurieCommon
import Foundation

public final class MockRunLoopAccessor: RunLoopAccessor {
    public enum Call: Equatable {
        case terminate
        case error(CurieCommon.CoreError)
    }

    public private(set) var calls: [Call] = []

    public init() {}

    public func terminate() {
        calls.append(.terminate)
    }

    public func error(_ error: CurieCommon.CoreError) {
        calls.append(.error(error))
    }
}
