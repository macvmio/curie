import Foundation

public final class Atomic<T> {
    private var value: T
    private let lock = NSLock()

    public init(value: T) {
        self.value = value
    }

    public func load() -> T {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    public func update(_ newValue: T) {
        lock.lock(); defer { lock.unlock() }
        value = newValue
    }
}
