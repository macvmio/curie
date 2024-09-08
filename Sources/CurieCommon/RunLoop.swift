//
//  RunLoop.swift
//
//
//  Created by Marcin Iwanicki on 08/09/2024.
//

import Foundation

public protocol RunLoopAccessor {
    func terminate()
    func error(_ error: CoreError)
}

public protocol RunLoop: RunLoopAccessor {
    func run(_ closure: @escaping (RunLoopAccessor) async throws -> Void) throws
}

public class DefaultRunLoop: RunLoop {
    public enum Interval: TimeInterval {
        case `default` = 1.0
        case short = 0.001
    }

    private var terminated = false
    private let lock = NSLock()
    private(set) var error: CoreError?

    private let interval: Interval

    public init(interval: Interval = .default) {
        self.interval = interval
    }

    public func run(_ closure: @escaping (any RunLoopAccessor) async throws -> Void) throws {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await closure(self)
                terminate()
            } catch let error as CoreError {
                self.error(error)
            } catch {
                self.error(.generic(error.localizedDescription))
            }
        }
        try run()
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

    private func run() throws {
        let sigint = makeSourceSignal(sig: SIGINT, eventHandler: .init(block: { [unowned self] in terminate() }))
        let sigterm = makeSourceSignal(sig: SIGTERM, eventHandler: .init(block: { [unowned self] in terminate() }))
        try withExtendedLifetime([sigint, sigterm]) {
            while !isTerminated() {
                Foundation.RunLoop.main.run(until: .now + interval.rawValue)
            }
            try rethrow()
        }
    }

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
