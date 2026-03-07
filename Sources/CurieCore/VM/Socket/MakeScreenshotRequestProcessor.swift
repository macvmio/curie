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
    private let screenshotter: Screenshotter

    init(screenshotter: Screenshotter) {
        self.screenshotter = screenshotter
    }

    func process(request: MakeScreenshotPayload) -> PromisedSocketResponse {
        DispatchQueue.main.sync {
            do {
                try screenshotter.makePngScreeshot(
                    vmWindow: NSApp.getSingleVmWindow(),
                    createPngImageAtPath: request.savePngImageAtPath,
                    includeClickVisualization: request.includeClickVisualization
                )
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

protocol Screenshotter: AnyObject {
    func makePngScreeshot(
        vmWindow: VMWindow,
        createPngImageAtPath: String,
        includeClickVisualization: Bool
    ) throws
}

enum ScreenshotterError: Error, CustomStringConvertible {
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

final class DefaultScreenshotter: Screenshotter {
    public func makePngScreeshot(
        vmWindow: VMWindow,
        createPngImageAtPath path: String,
        includeClickVisualization: Bool
    ) throws {
        let screenshot = try screenshotOfVm(
            vmWindow: vmWindow,
            includeClickVisualization: includeClickVisualization
        )
        let pngData = try pngData(from: screenshot)
        try pngData.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    private func screenshotOfVm(
        vmWindow: VMWindow,
        includeClickVisualization: Bool
    ) throws -> NSImage {
        let view = vmWindow.viewForMakingVmScreenshot(
            includeClickVisualization: includeClickVisualization
        )

        let bounds = view.bounds
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw ScreenshotterError.noBitmapImageRep
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
            throw ScreenshotterError.noPngData
        }
        return png
    }
}
