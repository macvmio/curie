import Foundation

struct VMInfo: Codable {
    let config: VMConfig
    let state: VMState
}

extension VMInfo: CustomStringConvertible {
    var description: String {
        """

        \(state.description)

        \(config.description)

        """
    }
}
