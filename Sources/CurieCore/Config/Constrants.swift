import CurieCommon
import Foundation
import TSCBasic

public enum Constants {
    public static let defaultDiskSize = MemorySize(bytes: 128 * 1024 * 1024 * 1024)
    public static let referenceFormat = "<repository>[:<tag>]"

    static let defaultConfig = VMConfig(
        cpuCount: 4,
        memorySize: .init(bytes: 4 * 1024 * 1024 * 1024),
        display: .init(width: 1920, height: 1080, pixelsPerInch: 144),
        network: .init(devices: [
            .init(macAddress: .automatic, mode: .NAT),
        ]),
        sharedDirectory: .init(directories: []),
        shutdown: .init(behaviour: .stop)
    )

    static let dataRootEnvironmentVariable = "CURIE_DATA_ROOT"
}
