import Darwin
import Foundation

public enum OutputStream {
    case stdout
    case stderr
}

public protocol Output: AnyObject {
    func write(_ string: String, to stream: OutputStream)

    func write(_ string: String)

    var redirected: Bool { get }
}

extension Output {
    public func write(_ string: String) {
        write(string, to: .stdout)
    }

    func write(_ data: Data, to stream: OutputStream) {
        guard let string = String(data: data, encoding: .utf8) else {
            return
        }
        write(string, to: stream)
    }

    func write(_ bytes: [UInt8], to stream: OutputStream) {
        write(Data(bytes), to: stream)
    }
}

public final class StandardOutput: Output {
    public static let shared = StandardOutput()

    private let lock = NSLock()

    private init() {}

    public func write(_ string: String, to stream: OutputStream) {
        lock.lock(); defer { lock.unlock() }
        switch stream {
        case .stdout:
            fputs(string, stdout)
            fflush(stdout)
        case .stderr:
            fputs(string, stderr)
            fflush(stderr)
        }
    }

    public var redirected: Bool {
        isatty(fileno(stdout)) != 1
    }
}

final class ForwardOutput: Output {
    let redirected = false

    private let forwardStdout: ((String) -> Void)?
    private let forwardStderr: ((String) -> Void)?

    init(stdout: ((String) -> Void)?, stderr: ((String) -> Void)?) {
        forwardStdout = stdout
        forwardStderr = stderr
    }

    public func write(_ string: String, to stream: OutputStream) {
        switch stream {
        case .stdout:
            forwardStdout?(string)
        case .stderr:
            forwardStderr?(string)
        }
    }
}

public final class CaptureOutput: Output {
    #if DEBUG
        public static let tests = CaptureOutput()
    #endif

    public let redirected = true

    private let lock = NSLock()

    public init() {}

    public private(set) var captured: [(OutputStream, String)] = []

    public var stdout: [String] { captured.filter { $0.0 == .stdout }.map(\.1) }
    public var stderr: [String] { captured.filter { $0.0 == .stderr }.map(\.1) }
    public var output: [String] { captured.map(\.1) }

    public var stdoutString: String { stdout.joined(separator: "\n") }
    public var stderrString: String { stderr.joined(separator: "\n") }
    public var outputString: String { output.joined(separator: "\n") }

    public func write(_ string: String, to stream: OutputStream) {
        lock.lock(); defer { lock.unlock() }
        switch stream {
        case .stdout:
            captured.append((.stdout, string))
        case .stderr:
            captured.append((.stderr, string))
        }
    }

    public func clear() {
        lock.lock(); defer { lock.unlock() }
        captured = []
    }
}

public final class CombinedOutput: Output {
    private let outputs: [Output]

    public init(outputs: [Output]) {
        self.outputs = outputs
    }

    public func write(_ string: String, to stream: OutputStream) {
        outputs.forEach { $0.write(string, to: stream) }
    }

    public var redirected: Bool {
        outputs.contains { $0.redirected }
    }
}
