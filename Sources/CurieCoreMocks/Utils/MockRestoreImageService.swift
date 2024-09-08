import CurieCore
import Foundation
import Virtualization

public final class MockRestoreImageService: RestoreImageService {
    public var mockLatestSupported: [CurieCore.RestoreImage] = []

    public init() {}

    public func latestSupported() async throws -> CurieCore.RestoreImage {
        guard let latestSupported = mockLatestSupported.popLast() else {
            fatalError("Missing mock latest supported")
        }
        return latestSupported
    }
}
