//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
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

import Foundation

enum InstallerState {
    case notInstalled
    case alreadyInstalled
    case installing
    case installed
    case failed(String)
}

@MainActor
final class AgentInstaller: ObservableObject {
    @Published var state: InstallerState = .notInstalled

    private let fileManager = FileManager.default

    private var installDirectory: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Curie")
    }

    private var agentPath: URL {
        installDirectory.appendingPathComponent("CurieAgent")
    }

    private var launchAgentDirectory: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }

    private var launchAgentPath: URL {
        launchAgentDirectory.appendingPathComponent("com.curie.agent.plist")
    }

    func checkInstallation() {
        if fileManager.fileExists(atPath: agentPath.path),
           fileManager.fileExists(atPath: launchAgentPath.path) {
            state = .alreadyInstalled
        } else {
            state = .notInstalled
        }
    }

    func install() {
        state = .installing

        Task {
            do {
                try await performInstallation()
                state = .installed
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func performInstallation() async throws {
        // Create install directory
        try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)

        // Copy the current executable to the install location
        let currentExecutable = URL(fileURLWithPath: CommandLine.arguments[0])
        let resolvedExecutable = try resolveExecutablePath(currentExecutable)

        // Remove old version if exists
        if fileManager.fileExists(atPath: agentPath.path) {
            try fileManager.removeItem(at: agentPath)
        }

        try fileManager.copyItem(at: resolvedExecutable, to: agentPath)

        // Make executable
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: agentPath.path)

        // Create LaunchAgents directory if needed
        try fileManager.createDirectory(at: launchAgentDirectory, withIntermediateDirectories: true)

        // Create LaunchAgent plist
        let launchAgentContent = createLaunchAgentPlist()
        try launchAgentContent.write(to: launchAgentPath, atomically: true, encoding: .utf8)

        // Unload old agent if running
        let unloadProcess = Process()
        unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unloadProcess.arguments = ["unload", launchAgentPath.path]
        try? unloadProcess.run()
        unloadProcess.waitUntilExit()

        // Load the new agent
        let loadProcess = Process()
        loadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        loadProcess.arguments = ["load", launchAgentPath.path]
        try loadProcess.run()
        loadProcess.waitUntilExit()

        if loadProcess.terminationStatus != 0 {
            throw InstallError.launchAgentLoadFailed
        }
    }

    private func resolveExecutablePath(_ url: URL) throws -> URL {
        // If running from an app bundle, get the actual executable
        var path = url.path

        // Resolve symlinks
        path = (try? fileManager.destinationOfSymbolicLink(atPath: path)) ?? path

        // If we're in a bundle, the executable might be in Contents/MacOS/
        if path.contains(".app/") {
            return URL(fileURLWithPath: path)
        }

        return URL(fileURLWithPath: path)
    }

    private func createLaunchAgentPlist() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.curie.agent</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(agentPath.path)</string>
                <string>--service</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>\(installDirectory.path)/agent.log</string>
            <key>StandardErrorPath</key>
            <string>\(installDirectory.path)/agent.log</string>
        </dict>
        </plist>
        """
    }
}

enum InstallError: LocalizedError {
    case launchAgentLoadFailed

    var errorDescription: String? {
        switch self {
        case .launchAgentLoadFailed:
            "Failed to load the launch agent. Please try again or install manually."
        }
    }
}
