import Foundation

struct VMState: Equatable, Codable {
    var id: ImageID
    var createdAt: Date
}

extension VMState: CustomStringConvertible {
    public var description: String {
        """
        State:
          id: \(id.description)
          createdAt: \(dateFormatter.string(from: createdAt))
        """
    }

    private var dateFormatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
}
