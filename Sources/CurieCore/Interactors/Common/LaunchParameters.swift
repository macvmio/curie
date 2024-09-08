//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
            sharedDirectory: prepareSharedDirectory(),
            shutdown: prepareShutdown()
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
        .init(behaviour: pauseOnExit ? .pause : .stop)
    }
}
