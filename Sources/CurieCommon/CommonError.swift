import Foundation

public struct SubprocessCoreError: Error {
    public let exitCode: Int32
}

public enum CoreError: LocalizedError {
    case generic(String)

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String
    ) throws -> T {
        try rethrow(closure(), .generic(message()))
    }

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ coreError: @autoclosure () -> CoreError
    ) throws -> T {
        do {
            return try closure()
        } catch {
            throw coreError()
        }
    }

    static func rethrow<T>(
        _ closure: @autoclosure () throws -> T,
        _ coreError: (String) -> CoreError
    ) throws -> T {
        do {
            return try closure()
        } catch let error as LocalizedError {
            throw coreError(error.localizedDescription)
        } catch {
            throw coreError(String(describing: error))
        }
    }

    static func rethrowCommand<T>(
        _ closure: () throws -> T,
        command: [String],
        message: String
    ) throws -> T {
        do {
            return try closure()
        } catch is SubprocessCoreError {
            throw CoreError.generic("""
            \(message)

            Failed command:
            > \(command.command())

            """)
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .generic(message):
            return message
        }
    }
}
