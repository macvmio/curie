import Foundation

public final class CommonAssembly: Assembly {
    public init() {}

    public func assemble(_ registry: Registry) {
        registry.register(Output.self) { _ in
            #if DEBUG
                return CombinedOutput(outputs: [StandardOutput.shared, CaptureOutput.tests])
            #else
                return StandardOutput.shared
            #endif
        }
        registry.register(Console.self) { r in
            DefaultConsole(output: r.resolve(Output.self))
        }
        registry.register(FileSystem.self) { _ in
            DefaultFileSystem()
        }
        registry.register(System.self) { _ in
            DefaultSystem()
        }
    }
}
