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

import CurieCommon
import Foundation

func printUsage() {
    print("""
    curie-agent - Clipboard sync agent for macOS VMs

    Usage:
        curie-agent [--help]

    Description:
        This agent runs inside a macOS VM and synchronizes the clipboard
        with the host machine running curie.

    Requirements:
        - Must be run inside a macOS VM created by curie
        - The VM must have clipboard sharing enabled (default)
        - The agent connects to the host via Virtio socket on port 52525

    Setup:
        1. Copy curie-agent binary into the VM (via shared folder)
        2. Run curie-agent manually or set up as a login item

    Options:
        --help    Show this help message

    """)
}

// Parse arguments
let args = CommandLine.arguments.dropFirst()
for arg in args {
    if arg == "--help" || arg == "-h" {
        printUsage()
        exit(0)
    }
}

// Create console and run the agent
let console = DefaultConsole(output: StandardOutput.shared)
let agent = AgentRunner(console: console)
agent.run()
