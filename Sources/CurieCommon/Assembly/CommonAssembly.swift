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
