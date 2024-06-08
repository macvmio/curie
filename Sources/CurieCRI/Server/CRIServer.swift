import Foundation
import GRPC
import NIO

public protocol CRIServer {
    func start() throws
}

final class DefaultCRIServer: CRIServer {
    func start() throws {
        // Create an event loop group for the server to run on.
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer {
            try! group.syncShutdownGracefully()
        }

        // Create a provider using the features we read.
        let provider = DefaultRuntime_V1_RuntimeServiceProvider()

        // Start the server and print its address once it has started.
        let server = Server.insecure(group: group)
            .withServiceProviders([provider])
            .bind(host: "localhost", port: 0)

        server.map(\.channel.localAddress).whenSuccess { address in
            print("server started on port \(address!.port!)")
        }

        // Wait on the server's `onClose` future to stop the program from exiting.
        _ = try server.flatMap(\.onClose).wait()
    }
}
