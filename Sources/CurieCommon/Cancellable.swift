import Foundation

public protocol Cancellable {
    func cancel()
    func isCancelled() -> Bool
}

public class StateCancellable: Cancellable {
    private var cancelled = false
    private let lock = NSLock()

    public init() {}

    public func cancel() {
        lock.lock(); defer { lock.unlock() }
        cancelled = true
    }

    public func isCancelled() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }
}
