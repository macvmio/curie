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
            StandardOutput.shared
        case .muted:
            ForwardOutput(stdout: nil, stderr: nil)
        case let .custom(output):
            output
        }
    }
}

public protocol System {
    func makeSIGINTSourceSignal(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) -> DispatchSourceSignal

    func makeSIGTERMSourceSignal(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) -> DispatchSourceSignal

    func keepAlive(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )

    func keepAliveWithSIGINTEventHandler(
        cancellable: Cancellable,
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )

    func execute(_ arguments: [String]) throws

    func execute(_ arguments: [String], output: OutputType) throws

    func environmentVariable(name: String) -> String?
}

final class DefaultSystem: System {
    private let environment = ProcessInfo.processInfo.environment

    func makeSIGINTSourceSignal(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) -> DispatchSourceSignal {
        signal(SIGINT, SIG_IGN)
        let sourceSignal = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sourceSignal.setEventHandler {
            signalHandler(exit)
        }
        sourceSignal.resume()
        return sourceSignal
    }

    func makeSIGTERMSourceSignal(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    ) -> DispatchSourceSignal {
        signal(SIGTERM, SIG_IGN)
        let sourceSignal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sourceSignal.setEventHandler {
            signalHandler(exit)
        }
        sourceSignal.resume()
        return sourceSignal
    }

    func keepAlive(
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
        let sigint = makeSIGINTSourceSignal(signalHandler: signalHandler)
        let sigterm = makeSIGTERMSourceSignal(signalHandler: signalHandler)
        withExtendedLifetime([sigint, sigterm]) {
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

    func environmentVariable(name: String) -> String? {
        ProcessInfo.processInfo.environment[name]
    }
}

private extension OutputType {
    func outputRedirection() -> TSCBasic.Process.OutputRedirection {
        switch self {
        case .default:
            .none
        default:
            .stream { [output] bytes in output.write(bytes, to: .stdout) }
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
