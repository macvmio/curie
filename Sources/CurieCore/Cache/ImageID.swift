import CryptoKit
import Foundation

struct ImageID: Hashable, CustomStringConvertible, Codable {
    private let rawValue: String

    enum CodingKeys: CodingKey {
        case rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    private init(rawValue: String) {
        self.rawValue = rawValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func make() -> ImageID {
        let uuid = UUID()
        let uuidData = uuid.uuidString.data(using: .utf8)!
        let hash = SHA256.hash(data: uuidData)
        let hashString = String(hash.compactMap { String(format: "%02x", $0) }.joined().prefix(12))
        return ImageID(rawValue: hashString)
    }

    var description: String {
        rawValue
    }
}
