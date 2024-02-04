import Foundation
import XCTest
import CurieCommon
import CurieCommonMocks
@testable import CurieCore

final class ImageCacheTests: XCTestCase {
    private var subject: DefaultImageCache!
    private var wallClock: MockWallClock

    override func setUp() {
        super.setUp()
        wallClock = MockWallClock()
//        subject = DefaultImageCache(
//            bundleParser: <#T##VMBundleParser#>,
//            wallClock: wallClock,
//            system: <#T##System#>,
//            fileSystem: <#T##FileSystem#>
//        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }
}
