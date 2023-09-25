import CurieCommon
import Foundation

public struct PsInteractorContext {
    public let format: OutputFormat

    public init(format: OutputFormat) {
        self.format = format
    }
}

public protocol PsInteractor {
    func execute(with context: PsInteractorContext) throws
}

final class DefaultPsInteractor: PsInteractor {
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

    func execute(with context: PsInteractorContext) throws {
        let items = try imageCache.listContainers()
        let images = items.sorted { $0.createAt > $1.createAt }

        let rendered = TableRenderer()
        let content = TableRenderer.Content(
            headers: [
                "container id",
                "repository",
                "tag",
                "created",
                "size",
                "name",
            ],
            values: images.map { [
                $0.reference.id.description,
                $0.reference.descriptor.repository,
                $0.reference.descriptor.tag ?? "<none>",
                dateFormatter.localizedString(for: $0.createAt, relativeTo: wallClock.now()),
                $0.size.description,
                $0.name ?? "<none>",
            ] }
        )
        let config = TableRenderer.Config(format: context.format.rendererFormat())
        let text = rendered.render(content: content, config: config)

        console.text(text)
    }
}
