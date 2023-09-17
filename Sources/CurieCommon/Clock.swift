import Foundation

public protocol WallClock {
    func now() -> Date
}

public final class DefaultWallClock: WallClock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
