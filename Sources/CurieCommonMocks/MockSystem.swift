import CurieCommon
import Foundation

public final class MockSystem: System {
    public enum Call: Equatable {
        case executeWithOutput([String])
    }

    public private(set) var calls: [Call] = []
    public var mockExecuteOutput: String?
    public var mockEnvironmentVariables: [String: String] = [:]

    public init() {}

    public func SIGINTEventHandler(signalHandler _: @escaping (@escaping (Int32) -> Never) -> Void)
        -> DispatchSourceSignal {
        fatalError("Not implemented yet")
    }

    public func keepAliveWithSIGINTEventHandler(signalHandler _: @escaping (@escaping (Int32) -> Never) -> Void) {
        fatalError("Not implemented yet")
    }

    public func keepAliveWithSIGINTEventHandler(
        cancellable _: CurieCommon.Cancellable,
        signalHandler _: @escaping (@escaping (Int32) -> Never) -> Void
    ) {
        fatalError("Not implemented yet")
    }

    public func execute(_: [String]) throws {
        fatalError("Not implemented yet")
    }

    public func execute(_ arguments: [String], output: CurieCommon.OutputType) throws {
        calls.append(.executeWithOutput(arguments))
        switch output {
        case .default:
            break
        case .muted:
            break
        case let .custom(output):
            if let mockExecuteOutput {
                output.write(mockExecuteOutput)
            }
        }
    }

    public func environmentVariable(name: String) -> String? {
        mockEnvironmentVariables[name]
    }
}
