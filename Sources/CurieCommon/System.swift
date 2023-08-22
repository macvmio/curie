import Dispatch
import Foundation

public protocol System {
    func keepAliveWithSIGINTEventHandler(
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )

    func keepAliveWithSIGINTEventHandler(
        cancellable: Cancellable,
        signalHandler: @escaping (@escaping (Int32) -> Never) -> Void
    )
}

final class DefaultSystem: System {
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
}
