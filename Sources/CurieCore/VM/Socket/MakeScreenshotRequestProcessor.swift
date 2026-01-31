//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AppKit
import CurieCommon
import Foundation

final class MakeScreenshotRequestProcessor {
    private let vmScreenshotter: VMScreenshotter

    init(vmScreenshotter: VMScreenshotter) {
        self.vmScreenshotter = vmScreenshotter
    }

    func process(request: MakeScreenshotPayload) -> PromisedSocketResponse {
        DispatchQueue.main.sync {
            do {
                try vmScreenshotter.makePngScreeshot(createPngImageAtPath: request.savePngImageAtPath)
                return ConstantPromisedSocketResponse(
                    response: .success(["imagePath": .string(request.savePngImageAtPath)]),
                    closeSocketAfterDeliveringResponse: false
                )
            } catch {
                return ConstantPromisedSocketResponse(
                    response: .error("Error making screnshot: \(error)"),
                    closeSocketAfterDeliveringResponse: false
                )
            }
        }
    }
}

protocol VMScreenshotter: AnyObject {
    func makePngScreeshot(createPngImageAtPath: String) throws
}

enum VMScreenshotterError: Error, CustomStringConvertible {
    case noWindow
    case noWindowContentView
    case noBitmapImageRep
    case noPngData

    var description: String {
        switch self {
        case .noWindow:
            "No VM window found"
        case .noWindowContentView:
            "No VM view found"
        case .noBitmapImageRep:
            "Failed to get bitmap of the screenshot"
        case .noPngData:
            "Failed to convert bitmap to PNG data"
        }
    }
}

final class VMScreenshotterImpl: VMScreenshotter {
    init() {}

    public func makePngScreeshot(createPngImageAtPath path: String) throws {
        let screenshot = try screenshotOfKeyWindow()
        let pngData = try pngData(from: screenshot)
        try pngData.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    private func screenshotOfKeyWindow() throws -> NSImage {
        guard let window = NSApp.windows.first else {
            throw VMScreenshotterError.noWindow
        }
        return try image(of: window)
    }

    private func image(of window: NSWindow) throws -> NSImage {
        guard let view = window.contentView else {
            throw VMScreenshotterError.noWindowContentView
        }

        let bounds = view.bounds
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw VMScreenshotterError.noBitmapImageRep
        }
        view.cacheDisplay(in: bounds, to: rep)

        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }

    private func pngData(from image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw VMScreenshotterError.noPngData
        }
        return png
    }
}
