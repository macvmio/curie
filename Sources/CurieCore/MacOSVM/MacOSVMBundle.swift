import CurieCommon
import Foundation
import TSCBasic

public struct MacOSVMBundle {
    public let path: AbsolutePath

    static let fileExtension = "curie"

    init(path: AbsolutePath) throws {
        guard path.pathString.hasSuffix(".\(MacOSVMBundle.fileExtension)") else {
            throw CoreError
                .generic("Invalid MacOSVMBundle, unexpected extension at path '\(path)' (expected <filename>.curie)")
        }
        self.path = path
    }

    public var name: String {
        path.basenameWithoutExt
    }

    public var machineIdentifier: AbsolutePath {
        vmComponent("vz-mac-machine-identifier.bin")
    }

    public var auxilaryStorage: AbsolutePath {
        vmComponent("vz-mac-auxilary-storage.bin")
    }

    public var hardwareModel: AbsolutePath {
        vmComponent("vz-mac-hardware-model.bin")
    }

    public var diskImage: AbsolutePath {
        vmComponent("vz-disk-image-storage-device-attachement.img")
    }

    public var config: AbsolutePath {
        path.appending(component: "config.json")
    }

    public var content: AbsolutePath {
        path.appending(component: "Content")
    }

    public var vm: AbsolutePath {
        content.appending(component: "VM")
    }

    // MARK: - Private

    private func vmComponent(_ filename: String) -> AbsolutePath {
        vm.appending(component: filename)
    }
}
