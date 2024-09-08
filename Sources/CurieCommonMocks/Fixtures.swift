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

import CurieCommon
import Foundation
import TSCBasic

public final class Fixtures {
    public final class CompressedBundle {
        public let path: AbsolutePath

        init(path: AbsolutePath) {
            self.path = path
        }
    }

    public final class Bundle {
        public let path: AbsolutePath

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

        public var allBinPaths: [AbsolutePath] {
            [
                machineIdentifier,
                auxilaryStorage,
                hardwareModel,
                diskImage,
            ]
        }

        public var allJsonPaths: [AbsolutePath] {
            [
                config,
                metadata,
                container,
            ]
        }

        public var allPaths: [AbsolutePath] {
            allBinPaths + allJsonPaths
        }

        init(path: AbsolutePath) {
            self.path = path
        }

        private func path(_ filename: String) -> AbsolutePath {
            path.appending(component: filename)
        }
    }

    private let fileManager = FileManager.default
    private var lastImageId = 1

    public init() {}

    public func makeImageBundle(at path: AbsolutePath) throws -> Fixtures.Bundle {
        try FileManager.default.createDirectory(at: path.asURL, withIntermediateDirectories: true)

        let bundle = Fixtures.Bundle(path: path)
        try bundle.allBinPaths.forEach {
            try write(content: $0.basename, toFileAtPath: $0)
        }
        try write(content: anyConfigJson, toFileAtPath: bundle.config)
        try write(content: anyMetadataJson, toFileAtPath: bundle.metadata)
        return bundle
    }

    public func zip(bundle: Fixtures.Bundle) throws -> AbsolutePath {
        let path = try AbsolutePath(validating: bundle.path.pathString + ".zip")
        try execute(["zip", "-r", "-X", path.pathString, bundle.path.pathString])
        return path
    }

    // MARK: - Private

    public var anyConfigJson: String {
        """
        {
          "cpuCount" : 8,
          "network" : {
            "devices" : [
              {
                "mode" : "NAT",
                "macAddress" : "synthesized"
              }
            ]
          },
          "display" : {
            "width" : 1920,
            "pixelsPerInch" : 80,
            "height" : 1080
          },
          "name" : "config-name",
          "memorySize" : "12 GB"
        }
        """
    }

    public var anyMetadataJson: String {
        """
        {
          "network" : {
            "devices" : {
              "0" : {
                "MACAddress" : "6e:9e:c0:f8:bf:b3"
              }
            }
          },
          "id" : "\(makeImageId())",
          "name" : "metadata-name",
          "createdAt" : "0001-01-01T00:00:00Z"
        }
        """
    }

    private func write(content: String, toFileAtPath path: AbsolutePath) throws {
        try content.write(to: path.asURL, atomically: true, encoding: .utf8)
    }

    private func execute(_ arguments: [String]) throws {
        do {
            let process = Process(
                arguments: arguments,
                outputRedirection: .none,
                startNewProcessGroup: false
            )
            try process.launch()
            _ = try process.waitUntilExit()
        } catch {
            throw CoreError.generic(error.localizedDescription)
        }
    }

    private func makeImageId() -> String {
        let id = lastImageId
        lastImageId += 1
        return id.description
    }
}
