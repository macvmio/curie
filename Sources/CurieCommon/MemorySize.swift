import Foundation

public struct MemorySize: Equatable, Codable, CustomStringConvertible, Comparable {
    public let bytes: UInt64

    enum Unit {
        case B
        case KB
        case MB
        case GB
    }

    private static let KB: UInt64 = 1024
    private static let MB: UInt64 = 1024 * 1024
    private static let GB: UInt64 = 1024 * 1024 * 1024

    // MARK: - Init

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let value = try MemorySize(string: container.decode(String.self)) else {
            throw CoreError.generic("Cannot decode FileSize")
        }
        self = value
    }

    public init(bytes: UInt64) {
        self.bytes = bytes
    }

    public init?(string: String) {
        let components = string.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard components.count == 2 else {
            return nil
        }
        guard let unit = MemorySize.unit(from: components[1]) else {
            return nil
        }
        let value = components[0]
        if let valueUInt64 = UInt64(value) {
            self = MemorySize(bytes: valueUInt64 * unit)
        } else if let valueDouble = Double(value) {
            self = MemorySize(bytes: UInt64(valueDouble * Double(unit)))
        } else {
            return nil
        }
    }

    // MARK: - Public

    public static var min: MemorySize {
        .init(bytes: .min)
    }

    public static var max: MemorySize {
        .init(bytes: .max)
    }

    public func delta(_ rhs: MemorySize) -> DeltaMemorySize {
        if rhs.bytes > bytes {
            return .greater(.init(bytes: rhs.bytes - bytes))
        }
        if rhs.bytes < bytes {
            return .lower(.init(bytes: bytes - rhs.bytes))
        }
        return .equal
    }

    // MARK: - CustomStringConvertable

    public var description: String {
        guard bytes >= MemorySize.KB else {
            return bytesString
        }
        guard bytes >= MemorySize.MB else {
            return kilobytesString
        }
        guard bytes >= MemorySize.GB else {
            return metabytesString
        }
        return gigabytesString
    }

    // MARK: - Comparable

    public static func < (lhs: MemorySize, rhs: MemorySize) -> Bool {
        lhs.bytes < rhs.bytes
    }

    // MARK: - Private

    private var kilobytes: Float {
        Float(bytes) / Float(MemorySize.KB)
    }

    private var megabytes: Float {
        Float(bytes) / Float(MemorySize.MB)
    }

    private var gigabytes: Float {
        Float(bytes) / Float(MemorySize.GB)
    }

    private var bytesString: String {
        String(format: "%ld B", bytes)
    }

    private var kilobytesString: String {
        String(format: "%.2f KB", kilobytes)
    }

    private var metabytesString: String {
        String(format: "%.2f MB", megabytes)
    }

    private var gigabytesString: String {
        String(format: "%.2f GB", gigabytes)
    }

    private static func unit(from string: String) -> UInt64? {
        switch string {
        case "B":
            return 1
        case "KB":
            return KB
        case "MB":
            return MB
        case "GB":
            return GB
        default:
            return nil
        }
    }
}

public enum DeltaMemorySize: Equatable, CustomStringConvertible {
    case lower(MemorySize)
    case greater(MemorySize)
    case equal

    public var description: String {
        switch self {
        case let .lower(fileSize):
            return "-\(fileSize.description)"
        case let .greater(fileSize):
            return "+\(fileSize.description)"
        case .equal:
            return "0"
        }
    }
}
