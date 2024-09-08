import CurieCommon
import Foundation

public final class MockOutput: Output {
    public enum Call: Equatable {
        case write(string: String, stream: CurieCommon.OutputStream)
    }

    public private(set) var calls: [Call] = []

    public func write(_ string: String, to stream: CurieCommon.OutputStream) {
        calls.append(.write(string: string, stream: stream))
    }

    public var redirected: Bool = false
}

public final class MockConsole: Console {
    public enum Call: Equatable {
        // swiftlint:disable:next duplicate_enum_cases
        case text(String)

        // swiftlint:disable:next duplicate_enum_cases
        case text(String, Bool)
        case error(String)
        case clear

        // swiftlint:disable:next duplicate_enum_cases
        case progress(String, Double)

        // swiftlint:disable:next duplicate_enum_cases
        case progress(String, Double, String?)
    }

    public private(set) var calls: [Call] = []

    public var output: any CurieCommon.Output = MockOutput()
    public var quiet: Bool = false

    public init() {}

    public func text(_ message: String) {
        calls.append(.text(message))
    }

    public func text(_ message: String, always: Bool) {
        calls.append(.text(message, always))
    }

    public func error(_ message: String) {
        calls.append(.error(message))
    }

    public func clear() {
        calls.append(.clear)
    }

    public func progress(prompt: String, progress: Double) {
        calls.append(.progress(prompt, progress))
    }

    public func progress(prompt: String, progress: Double, suffix: String?) {
        calls.append(.progress(prompt, progress, suffix))
    }
}
