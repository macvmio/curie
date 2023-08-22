import CurieCommon
import Foundation
import TSCBasic

public enum Constants {
    public static let defaultDiskSize = MemorySize(bytes: 128 * 1024 * 1024 * 1024)

    static let defaultConfig = VMConfig(
        name: "Anonymous VM",
        cpuCount: 4,
        memorySize: .init(bytes: 4 * 1024 * 1024 * 1024),
        display: .init(width: 1920, height: 1080, pixelsPerInch: 80),
        network: .init(devices: [
            .init(macAddress: .automatic, mode: .NAT),
        ])
    )
}
