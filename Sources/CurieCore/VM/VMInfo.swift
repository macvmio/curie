import Foundation

struct VMInfo: Codable {
    let config: VMConfig
    let metadata: VMMetadata
}

extension VMInfo: CustomStringConvertible {
    var description: String {
        """

        \(metadata.description)

        \(config.description)

        """
    }
}
