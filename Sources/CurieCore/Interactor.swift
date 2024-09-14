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

public enum Operation {
    case build(BuildParameters)
    case clone(CloneParameters)
    case commit(CommitParameters)
    case config(ConfigParameters)
    case create(CreateParameters)
    case download(DownloadParameters)
    case export(ExportParameters)
    case images(ImagesParameters)
    case `import`(ImportParameters)
    case inspect(InspectParameters)
    case ps(PsParameters)
    case rmi(RmiParameters)
    case rm(RmParameters)
    case run(RunParameters)
}

public protocol Interactor {
    func execute(_ operation: Operation) throws
}

protocol AsyncInteractor: AnyObject {
    associatedtype Parameters

    func execute(parameters: Parameters) async throws
}

final class DefaultInteractor: Interactor {
    private let buildInteractor: BuildInteractor
    private let cloneInteractor: CloneInteractor
    private let commitInteractor: CommitInteractor
    private let configInteractor: ConfigInteractor
    private let createInteractor: CreateInteractor
    private let downloadInteractor: DownloadInteractor
    private let exportInteractor: ExportInteractor
    private let imagesInteractor: ImagesInteractor
    private let importInteractor: ImportInteractor
    private let inspectInteractor: InspectInteractor
    private let psInteractor: PsInteractor
    private let rmiInteractor: RmiInteractor
    private let rmInteractor: RmInteractor
    private let runInteractor: RunInteractor
    private let runLoop: CurieCommon.RunLoop

    init(
        buildInteractor: BuildInteractor,
        cloneInteractor: CloneInteractor,
        commitInteractor: CommitInteractor,
        configInteractor: ConfigInteractor,
        createInteractor: CreateInteractor,
        downloadInteractor: DownloadInteractor,
        exportInteractor: ExportInteractor,
        imagesInteractor: ImagesInteractor,
        importInteractor: ImportInteractor,
        inspectInteractor: InspectInteractor,
        psInteractor: PsInteractor,
        rmiInteractor: RmiInteractor,
        rmInteractor: RmInteractor,
        runInteractor: RunInteractor,
        runLoop: CurieCommon.RunLoop
    ) {
        self.buildInteractor = buildInteractor
        self.cloneInteractor = cloneInteractor
        self.commitInteractor = commitInteractor
        self.configInteractor = configInteractor
        self.createInteractor = createInteractor
        self.downloadInteractor = downloadInteractor
        self.exportInteractor = exportInteractor
        self.imagesInteractor = imagesInteractor
        self.importInteractor = importInteractor
        self.inspectInteractor = inspectInteractor
        self.psInteractor = psInteractor
        self.rmiInteractor = rmiInteractor
        self.rmInteractor = rmInteractor
        self.runInteractor = runInteractor
        self.runLoop = runLoop
    }

    // swiftlint:disable:next cyclomatic_complexity
    func execute(_ operation: Operation) throws {
        try runLoop.run { [self] _ in
            switch operation {
            case let .build(parameters):
                try await buildInteractor.execute(parameters: parameters)
            case let .clone(parameters):
                try await cloneInteractor.execute(parameters: parameters)
            case let .commit(parameters):
                try await commitInteractor.execute(parameters: parameters)
            case let .config(parameters):
                try await configInteractor.execute(parameters: parameters)
            case let .create(parameters):
                try await createInteractor.execute(parameters: parameters)
            case let .download(parameters):
                try await downloadInteractor.execute(parameters: parameters)
            case let .export(parameters):
                try await exportInteractor.execute(parameters: parameters)
            case let .images(parameters):
                try await imagesInteractor.execute(parameters: parameters)
            case let .import(parameters):
                try await importInteractor.execute(parameters: parameters)
            case let .inspect(parameters):
                try await inspectInteractor.execute(parameters: parameters)
            case let .ps(parameters):
                try await psInteractor.execute(parameters: parameters)
            case let .rmi(parameters):
                try await rmiInteractor.execute(parameters: parameters)
            case let .rm(parameters):
                try await rmInteractor.execute(parameters: parameters)
            case let .run(parameters):
                try await runInteractor.execute(parameters: parameters)
            }
        }
    }
}
