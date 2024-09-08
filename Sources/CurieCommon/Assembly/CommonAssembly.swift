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

import Foundation
import SCInject

public final class CommonAssembly: Assembly {
    public init() {}

    public func assemble(_ registry: Registry) {
        registry.register(Output.self) { _ in
            StandardOutput.shared
        }
        registry.register(Console.self) { r in
            DefaultConsole(output: r.resolve(Output.self))
        }
        registry.register(WallClock.self) { _ in
            DefaultWallClock()
        }
        registry.register(FileSystem.self) { _ in
            DefaultFileSystem()
        }
        registry.register(System.self) { _ in
            DefaultSystem()
        }
        registry.register(RunLoop.self, .container) { _ in
            DefaultRunLoop()
        }
        registry.register(HTTPClient.self) { _ in
            URLSessionHTTPClient()
        }
    }
}
