import CurieCommon
import Foundation

public final class MockWallClock: WallClock {
    public var mockNow: Date = .now

    public init() {}

    public func now() -> Date {
        mockNow
    }
}
