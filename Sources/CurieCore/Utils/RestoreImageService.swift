import Foundation
import Virtualization

public struct RestoreImage: Equatable {
    var url: URL
    var isSupported: Bool
    var buildVersion: String
    var operatingSystemVersion: String

    public init(url: URL, isSupported: Bool, buildVersion: String, operatingSystemVersion: String) {
        self.url = url
        self.isSupported = isSupported
        self.buildVersion = buildVersion
        self.operatingSystemVersion = operatingSystemVersion
    }
}

public protocol RestoreImageService {
    func latestSupported() async throws -> RestoreImage
}

final class DefaultRestoreImageService: RestoreImageService {
    func latestSupported() async throws -> RestoreImage {
        try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.fetchLatestSupported { result in
                switch result {
                case let .success(restoreImage):
                    continuation.resume(returning: .init(
                        url: restoreImage.url,
                        isSupported: restoreImage.isSupported,
                        buildVersion: restoreImage.buildVersion,
                        operatingSystemVersion: restoreImage.operatingSystemVersion.description
                    ))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension OperatingSystemVersion {
    var description: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}
