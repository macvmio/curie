import Foundation
import TSCBasic
import TSCLibc

public protocol Directory {
    var path: AbsolutePath { get }
}

final class PredefinedDirectory: Directory {
    let path: AbsolutePath

    init(path: AbsolutePath) {
        self.path = path
    }
}

public final class TemporaryDirectory: Directory {
    public let path: AbsolutePath

    private let fileManager = FileManager.default

    init() throws {
        let path = try determineTempDirectory(nil).appending(RelativePath("curie.XXXXXX"))

        // Convert path to a C style string terminating with null char to be an valid input
        // to mkdtemp method. The XXXXXX in this string will be replaced by a random string
        // which will be the actual path to the temporary directory.
        var template = [UInt8](path.pathString.utf8).map { Int8($0) } + [Int8(0)]

        if TSCLibc.mkdtemp(&template) == nil {
            throw MakeDirectoryError.other(errno)
        }

        self.path = try AbsolutePath(validating: String(cString: template))
    }

    deinit {
        _ = try? fileManager.removeItem(atPath: path.pathString)
    }
}
