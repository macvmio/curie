import CurieCommon
import Foundation
import TSCBasic

public struct VMBundle {
    public let path: AbsolutePath

    static let fileExtension = "curie"

    init(path: AbsolutePath) {
        self.path = path
    }

    public var name: String {
        path.basename
    }

    public var machineIdentifier: AbsolutePath {
        path("machine-identifier.bin")
    }

    public var auxilaryStorage: AbsolutePath {
        path("auxilary-storage.bin")
    }

    public var hardwareModel: AbsolutePath {
        path("hardware-model.bin")
    }

    public var diskImage: AbsolutePath {
        path("disk.img")
    }

    public var config: AbsolutePath {
        path("config.json")
    }

    public var metadata: AbsolutePath {
        path("metadata.json")
    }

    public var container: AbsolutePath {
        path("container.json")
    }

    public var machineState: AbsolutePath {
        path("machine-state.bin")
    }

    // MARK: - Private

    private func path(_ filename: String) -> AbsolutePath {
        path.appending(component: filename)
    }
}
