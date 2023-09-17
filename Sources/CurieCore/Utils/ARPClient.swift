import CurieCommon
import Foundation

struct ARPARow: Equatable, Codable {
    let ip: String
    let macAddress: String
}

protocol ARPClient {
    func executeARPA() throws -> [ARPARow]
}

final class DefaultARPClient: ARPClient {
    private let system: System

    init(system: System) {
        self.system = system
    }

    func executeARPA() throws -> [ARPARow] {
        let captureOutput = CaptureOutput()
        try system.execute(["arp", "-a"], output: .custom(captureOutput))

        let tokens = captureOutput.outputString
            .split(separator: "\n")
            .map { $0.split(separator: " ") }

        let items: [ARPARow] = tokens
            .filter { $0.count >= 4 }
            .compactMap {
                guard let macAddress = parseMAC(raw: $0[3]) else {
                    return nil
                }
                return ARPARow(
                    ip: parseIP(raw: $0[1]),
                    macAddress: macAddress
                )
            }

        return items
    }

    private func parseIP(raw: Substring.SubSequence) -> String {
        String(raw.dropFirst().dropLast())
    }

    private func parseMAC(raw: Substring.SubSequence) -> String? {
        let components = raw.split(separator: ":")
        guard components.count == 6 else {
            return nil
        }
        let normalizedComponents = components.map {
            if $0.count == 1 {
                return "0\($0.lowercased())"
            } else {
                return $0.lowercased()
            }
        }
        return normalizedComponents.joined(separator: ":")
    }
}
