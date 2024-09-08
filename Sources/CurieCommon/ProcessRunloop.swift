//
//  ProcessRunloop.swift
//
//
//  Created by Marcin Iwanicki on 08/09/2024.
//

import Foundation

public protocol AccessProcessRunloop {
    func terminate()
    func error(_ error: CoreError)
}

public protocol ProcessRunloop: AccessProcessRunloop {
    func run() throws
}

public class DefaultProcessRunloop: ProcessRunloop {
    private var terminated = false
    private let lock = NSLock()
    private(set) var error: CoreError?

    public init() {}

    public func run() throws {
        let sigint = makeSourceSignal(sig: SIGINT, eventHandler: .init(block: { [unowned self] in terminate() }))
        let sigterm = makeSourceSignal(sig: SIGTERM, eventHandler: .init(block: { [unowned self] in terminate() }))
        try withExtendedLifetime([sigint, sigterm]) {
            while !isTerminated() {
                RunLoop.main.run(until: .now + 1)
            }
            try rethrow()
        }
    }

    public func terminate() {
        lock.lock(); defer { lock.unlock() }
        terminated = true
    }

    public func error(_ error: CoreError) {
        lock.lock(); defer { lock.unlock() }
        self.error = error
        terminated = true
    }

    // MARK: - Private

    private func isTerminated() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return terminated
    }

    private func rethrow() throws {
        lock.lock(); defer { lock.unlock() }
        if let error {
            throw error
        }
    }

    private func makeSourceSignal(
        sig: Int32,
        eventHandler: DispatchWorkItem
    ) -> DispatchSourceSignal {
        signal(sig, SIG_IGN)
        let sourceSignal = DispatchSource.makeSignalSource(signal: sig, queue: .main)
        sourceSignal.setEventHandler(handler: eventHandler)
        sourceSignal.resume()
        return sourceSignal
    }
}
