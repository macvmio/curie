import AppKit
import CurieCommon
import Foundation

public struct LaunchParameters {
    public var noWindow: Bool
    public var mainScreenResolution: Bool
    public var recoveryMode: Bool
    public var shareCurrentWorkingDirectory: Bool
    public var pauseOnExit: Bool

    public init(
        noWindow: Bool,
        mainScreenResolution: Bool,
        recoveryMode: Bool,
        shareCurrentWorkingDirectory: Bool,
        pauseOnExit: Bool
    ) {
        self.noWindow = noWindow
        self.mainScreenResolution = mainScreenResolution
        self.recoveryMode = recoveryMode
        self.shareCurrentWorkingDirectory = shareCurrentWorkingDirectory
        self.pauseOnExit = pauseOnExit
    }

    func partialConfig() throws -> VMPartialConfig {
        try .init(
            display: prepareDisplay(),
            sharedDirectory: prepareSharedDirectory()
        )
    }

    // MARK: - Private

    private func prepareDisplay() throws -> VMPartialConfig.DisplayPartialConfig? {
        guard mainScreenResolution else {
            return nil
        }
        guard let frame = NSScreen.main else {
            throw CoreError.generic("Failed to identify the main screen")
        }
        return .init(
            width: Int(frame.frame.width * frame.backingScaleFactor),
            height: Int(frame.frame.height * frame.backingScaleFactor),
            pixelsPerInch: Int(frame.dpi.width)
        )
    }

    private func prepareSharedDirectory() -> VMConfig.SharedDirectoryConfig? {
        guard shareCurrentWorkingDirectory else {
            return nil
        }
        return .init(directories: [.currentWorkingDirectory(options: .init())])
    }

    private func prepareShutdown() -> VMConfig.ShutdownConfig? {
        .init(behaviour: pauseOnExit ? .pause : .exit)
    }
}
