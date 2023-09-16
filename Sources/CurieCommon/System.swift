import Dispatch
import Foundation
import TSCBasic

public enum OutputType {
    case `default`
    case muted
    case custom(Output)

    var output: Output {
        switch self {
        case .default:
            return StandardOutput.shared
        case .muted:
            return ForwardOutput(stdout: nil, stderr: nil)
        case let .custom(output):
            return output
        }
    }
}

public protocol System {
    func keepAliveWithSIGINTEventHandler(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )

    func keepAliveWithSIGINTEventHandler(
        cancellable: Cancellable,
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )

    func execute(_ arguments: [String]) throws

    func execute(_ arguments: [String], output: OutputType) throws
}

final class DefaultSystem: System {
    private let environment = ProcessInfo.processInfo.environment

    func keepAliveWithSIGINTEventHandler(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) {
        keepAliveWithSIGINTEventHandler(
            cancellable: StateCancellable(),
            signalHandler: signalHandler
        )
    }

    func keepAliveWithSIGINTEventHandler(
        cancellable: Cancellable,
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) {
        signal(SIGINT, SIG_IGN)
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signalSource.setEventHandler {
            signalHandler(exit)
        }
        signalSource.resume()

        withExtendedLifetime(signalSource) {
            while !cancellable.isCancelled() {
                RunLoop.main.run(until: .now + 1)
            }
        }
    }

    func execute(_ arguments: [String]) throws {
        try execute(arguments, output: .default)
    }

    func execute(_ arguments: [String], output: OutputType) throws {
        let result: ProcessResult
        do {
            let process = Process(
                arguments: arguments,
                outputRedirection: output.outputRedirection(),
                startNewProcessGroup: false
            )
            try process.launch()
            result = try process.waitUntilExit()
        } catch {
            throw CoreError.generic(error.localizedDescription)
        }
        try result.throwIfErrored()
    }
}

private extension OutputType {
    func outputRedirection() -> TSCBasic.Process.OutputRedirection {
        switch self {
        case .default:
            return .none
        default:
            return .stream { [output] bytes in output.write(bytes, to: .stdout) }
                stderr: { [output] bytes in output.write(bytes, to: .stderr)
                }
        }
    }
}

private extension ProcessResult {
    func throwIfErrored() throws {
        switch exitStatus {
        case let .signalled(signal: code):
            throw SubprocessCoreError(exitCode: code)
        case let .terminated(code: code):
            guard code == 0 else {
                throw SubprocessCoreError(exitCode: code)
            }
        }
    }
}
