import CurieCommon
import Foundation

public struct ListInteractorContext {
    public enum Format {
        case text
        case json
    }

    public let format: Format

    public init(format: Format) {
        self.format = format
    }
}

public protocol ListInteractor {
    func execute(with context: ListInteractorContext) throws
}

final class DefaultListInteractor: ListInteractor {
    private let imageCache: ImageCache
    private let console: Console

    init(
        imageCache: ImageCache,
        console: Console
    ) {
        self.imageCache = imageCache
        self.console = console
    }

    func execute(with context: ListInteractorContext) throws {
        let images = try imageCache.listImages().sorted {
            if $0.reference.descriptor.repository == $1.reference.descriptor.repository {
                return $0.reference.descriptor.tag ?? "" > $1.reference.descriptor.tag ?? ""
            } else {
                return $0.reference.descriptor.repository > $1.reference.descriptor.repository
            }
        }

        let rendered = TableRenderer()

        let content = TableRenderer.Content(
            headers: [
                "repository", "tag", "image id",
            ],
            values: images.map { [
                $0.reference.descriptor.repository,
                $0.reference.descriptor.tag ?? "<none>",
                $0.reference.id.description,
            ] }
        )

        let config = TableRenderer.Config(format: context.format.rendererFormat())

        let text = rendered.render(content: content, config: config)

        console.text(text)
    }
}

private extension ListInteractorContext.Format {
    func rendererFormat() -> TableRenderer.Format {
        switch self {
        case .text:
            return .text
        case .json:
            return .json
        }
    }
}
