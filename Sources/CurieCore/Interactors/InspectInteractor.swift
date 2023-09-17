import CurieCommon
import Foundation

public struct InspectInteractorContext {
    public var reference: String
    public let format: OutputFormat

    public init(
        reference: String,
        format: OutputFormat
    ) {
        self.reference = reference
        self.format = format
    }
}

public protocol InspectInteractor {
    func execute(with context: InspectInteractorContext) throws
}

final class DefaultInspectInteractor: InspectInteractor {
    private let imageCache: ImageCache
    private let bundleParser: VMBundleParser
    private let console: Console

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(
        imageCache: ImageCache,
        bundleParser: VMBundleParser,
        console: Console
    ) {
        self.imageCache = imageCache
        self.bundleParser = bundleParser
        self.console = console
    }

    func execute(with context: InspectInteractorContext) throws {
        let reference = try imageCache.findReference(context.reference)
        let bundle = VMBundle(path: imageCache.path(to: reference))
        let config = try bundleParser.readConfig(from: bundle)
        let state = try bundleParser.readState(from: bundle)
        let item = InspectItem(config: config, state: state)

        switch context.format {
        case .text:
            renderText(item)
        case .json:
            try renderJson(item)
        }
    }

    // MARK: - Private

    private func renderText(_ item: InspectItem) {
        console.text("")
        console.text(item.state.description)
        console.text("")
        console.text(item.config.description)
        console.text("")
    }

    private func renderJson(_ item: InspectItem) throws {
        let data = try jsonEncoder.encode(item)
        guard let string = String(data: data, encoding: .utf8) else {
            return
        }
        console.text(string)
    }
}

private struct InspectItem: Encodable {
    let config: VMConfig
    let state: VMState
}
