//
// Copyright 2024 Marcin Iwanicki, Tomasz Jarosik, and contributors
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

import CurieCommon
import Foundation
import SCInject

// swiftlint:disable function_body_length
public final class CoreAssembly: Assembly {
    public init() {}

    public func assemble(_ registry: Registry) {
        assembleInteractors(registry)
        assembleUtils(registry)
    }

    // MARK: - Private

    private func assembleInteractors(_ registry: Registry) {
        registry.register(Interactor.self) { r in
            DefaultInteractor(
                buildInteractor: r.resolve(BuildInteractor.self),
                cloneInteractor: r.resolve(CloneInteractor.self),
                commitInteractor: r.resolve(CommitInteractor.self),
                configInteractor: r.resolve(ConfigInteractor.self),
                createInteractor: r.resolve(CreateInteractor.self),
                downloadInteractor: r.resolve(DownloadInteractor.self),
                exportInteractor: r.resolve(ExportInteractor.self),
                imagesInteractor: r.resolve(ImagesInteractor.self),
                importInteractor: r.resolve(ImportInteractor.self),
                inspectInteractor: r.resolve(InspectInteractor.self),
                psInteractor: r.resolve(PsInteractor.self),
                runLoop: r.resolve(CurieCommon.RunLoop.self)
            )
        }
        registry.register(RunInteractor.self) { r in
            DefaultRunInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageRunner: r.resolve(ImageRunner.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(StartInteractor.self) { r in
            DefaultStartInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageRunner: r.resolve(ImageRunner.self),
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(BuildInteractor.self) { r in
            BuildInteractor(
                configurator: r.resolve(VMConfigurator.self),
                installer: r.resolve(VMInstaller.self),
                imageCache: r.resolve(ImageCache.self),
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(ImagesInteractor.self) { r in
            ImagesInteractor(
                imageCache: r.resolve(ImageCache.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(RmInteractor.self) { r in
            DefaultRmInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(RmiInteractor.self) { r in
            DefaultRmiInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CloneInteractor.self) { r in
            CloneInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(InspectInteractor.self) { r in
            InspectInteractor(
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                aprClient: r.resolve(ARPClient.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CreateInteractor.self) { r in
            CreateInteractor(
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(CommitInteractor.self) { r in
            CommitInteractor(
                configurator: r.resolve(VMConfigurator.self),
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(PsInteractor.self) { r in
            PsInteractor(
                imageCache: r.resolve(ImageCache.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(DownloadInteractor.self) { r in
            DownloadInteractor(
                restoreImageService: r.resolve(RestoreImageService.self),
                httpClient: r.resolve(HTTPClient.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ExportInteractor.self) { r in
            ExportInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImportInteractor.self) { r in
            ImportInteractor(
                imageCache: r.resolve(ImageCache.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ConfigInteractor.self) { r in
            ConfigInteractor(
                imageCache: r.resolve(ImageCache.self),
                system: r.resolve(System.self)
            )
        }
    }

    private func assembleUtils(_ registry: Registry) {
        registry.register(VMBundleParser.self) { r in
            DefaultVMBundleParser(
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(VMConfigurator.self) { r in
            DefaultVMConfigurator(
                bundleParser: r.resolve(VMBundleParser.self),
                fileSystem: r.resolve(FileSystem.self),
                wallClock: r.resolve(WallClock.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(MacOSWindowAppLauncher.self) { _ in
            MacOSWindowAppLauncher()
        }
        registry.register(VMInstaller.self) { r in
            DefaultVMInstaller(
                console: r.resolve(Console.self)
            )
        }
        registry.register(ImageCache.self) { r in
            DefaultImageCache(
                bundleParser: r.resolve(VMBundleParser.self),
                wallClock: r.resolve(WallClock.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self)
            )
        }
        registry.register(ImageRunner.self) { r in
            DefaultImageRunner(
                windowAppLauncher: r.resolve(MacOSWindowAppLauncher.self),
                imageCache: r.resolve(ImageCache.self),
                bundleParser: r.resolve(VMBundleParser.self),
                system: r.resolve(System.self),
                fileSystem: r.resolve(FileSystem.self),
                console: r.resolve(Console.self)
            )
        }
        registry.register(ARPClient.self) { r in
            DefaultARPClient(
                system: r.resolve(System.self)
            )
        }
        registry.register(RestoreImageService.self) { _ in
            DefaultRestoreImageService()
        }
    }
}

// swiftlint:enable function_body_length
