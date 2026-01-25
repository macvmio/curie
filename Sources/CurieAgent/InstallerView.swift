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

import AppKit
import SwiftUI

struct InstallerView: View {
    @StateObject private var installer = AgentInstaller()

    var body: some View {
        VStack(spacing: 20) {
            // Logo
            logoImage
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            // Title
            Text("Curie Agent")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            // Description
            Text("Enables clipboard sharing between this VM and the host Mac.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Spacer()

            // Status or Install Button
            switch installer.state {
            case .notInstalled:
                Button(action: { installer.install() }) {
                    Text("Install")
                        .frame(minWidth: 120)
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .controlSize(.large)

            case .installing:
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Installing...")
                    .foregroundColor(.gray)

            case .installed:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.green)
                Text("Installed successfully!")
                    .foregroundColor(.gray)
                Text("The agent will start automatically on login.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .padding(.top, 8)

            case let .failed(error):
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.red)
                Text("Installation failed")
                    .foregroundColor(.red)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)

                Button("Try Again") {
                    installer.install()
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .padding(.top, 8)

            case .alreadyInstalled:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.green)
                Text("Already installed")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Reinstall") {
                        installer.install()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(.black)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(30)
        .frame(width: 400, height: 320)
        .background(Color.white)
        .onAppear {
            installer.checkInstallation()
        }
    }

    private var logoImage: Image {
        // Use the app's icon from the bundle
        if let nsImage = NSApp.applicationIconImage {
            return Image(nsImage: nsImage)
        }
        // Fallback to system icon
        return Image(systemName: "doc.on.clipboard")
    }
}
