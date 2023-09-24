import CurieCommon
import Foundation

public struct ImagesInteractorContext {
    public let format: OutputFormat

    public init(format: OutputFormat) {
        self.format = format
    }
}

public protocol ImagesInteractor {
    func execute(with context: ImagesInteractorContext) throws
}

final class DefaultImagesInteractor: ImagesInteractor {
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

    func execute(with context: ImagesInteractorContext) throws {
        let items = try imageCache.listImages()
        let images = items.sorted { $0.createAt > $1.createAt }

        let rendered = TableRenderer()
        let content = TableRenderer.Content(
            headers: [
                "repository",
                "tag",
                "image id",
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
