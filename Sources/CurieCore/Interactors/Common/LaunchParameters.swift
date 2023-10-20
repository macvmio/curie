import Foundation

public struct LaunchParameters {
    public var noWindow: Bool
    public var recoveryMode: Bool
    public var shareCurrentWorkingDirectory: Bool

    public init(noWindow: Bool, recoveryMode: Bool, shareCurrentWorkingDirectory: Bool) {
        self.noWindow = noWindow
        self.recoveryMode = recoveryMode
        self.shareCurrentWorkingDirectory = shareCurrentWorkingDirectory
    }

    func partialConfig() -> VMPartialConfig {
        let sharedDirectoryConfig = shareCurrentWorkingDirectory
            ? VMConfig.SharedDirectoryConfig(directories: [.currentWorkingDirectory(options: .init())])
            : nil
        return .init(sharedDirectory: sharedDirectoryConfig)
    }
}
