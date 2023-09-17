import CurieCommon
import Foundation

public struct ListInteractorContext {
    public enum Format {
        case text
        case json
    }

    public let listContainers: Bool
    public let format: Format

    public init(listContainers: Bool, format: Format) {
        self.listContainers = listContainers
        self.format = format
    }
}

public protocol ListInteractor {
    func execute(with context: ListInteractorContext) throws
}

final class DefaultListInteractor: ListInteractor {
    private let imageCache: ImageCache
    private let wallClock: WallClock
    private let console: Console

    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(
        imageCache: ImageCache,
        wallClock: WallClock,
        console: Console
    ) {
        self.imageCache = imageCache
        self.wallClock = wallClock
        self.console = console
    }

    func execute(with context: ListInteractorContext) throws {
        let items = try context.listContainers
            ? imageCache.listContainers()
            : imageCache.listImages()
        let images = items.sorted { $0.createAt > $1.createAt }

        let rendered = TableRenderer()
        let content = TableRenderer.Content(
            headers: [
                "repository",
                "tag",
                context.listContainers ? "container id" : "image id",
                "created",
                "size",
            ],
            values: images.map { [
                $0.reference.descriptor.repository,
                $0.reference.descriptor.tag ?? "<none>",
                $0.reference.id.description,
                dateFormatter.localizedString(for: $0.createAt, relativeTo: wallClock.now()),
                $0.size.description,
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
