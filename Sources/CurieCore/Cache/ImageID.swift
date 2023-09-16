import CryptoKit
import Foundation

struct ImageID: Hashable, CustomStringConvertible, Codable {
    private let rawID: String

    private init(rawID: String) {
        self.rawID = rawID
    }

    static func make() -> ImageID {
        let uuid = UUID()
        let uuidData = uuid.uuidString.data(using: .utf8)!
        let hash = SHA256.hash(data: uuidData)
        let hashString = String(hash.compactMap { String(format: "%02x", $0) }.joined().prefix(12))
        return ImageID(rawID: hashString)
    }

    var description: String {
        rawID
    }
}
