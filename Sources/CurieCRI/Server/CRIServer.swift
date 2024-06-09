import CurieCommon
import Foundation
import GRPC
import NIO

public struct CRIServerConfig {
    let host: String
    let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
}

public protocol CRIServer {
    func start(config: CRIServerConfig) throws
}

final class DefaultCRIServer: CRIServer {
    private let console: Console

    init(console: Console) {
        self.console = console
    }

    func start(config: CRIServerConfig) throws {
        // Create an event loop group for the server to run on.
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer {
            try! group.syncShutdownGracefully()
        }

        // Create a provider using the features we read.
        let runtimeServiceProvider = DefaultRuntime_V1_RuntimeServiceProvider()

        // Start the server and print its address once it has started.
        let server = Server.insecure(group: group)
            .withServiceProviders([runtimeServiceProvider])
            .bind(host: config.host, port: config.port)

        server.map(\.channel.localAddress).whenSuccess { [console] address in
            console.text("Server started on port \(address!.port!)")
        }

        // Wait on the server's `onClose` future to stop the program from exiting.
        do {
            _ = try server.flatMap(\.onClose).wait()
        } catch {
            try group.syncShutdownGracefully()
        }
    }
}
