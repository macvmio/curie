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

import ArgumentParser
import CurieCommon
import CurieCore
import Foundation
import SCInject

private enum Setup {
    static let allSubcommands: [(ParsableCommand.Type, Assembly)] = [
        (BuildCommand.self, BuildCommand.Assembly()),
        (CloneCommand.self, CloneCommand.Assembly()),
        (ConfigCommand.self, ConfigCommand.Assembly()),
        (CreateCommand.self, CreateCommand.Assembly()),
        (CommitCommand.self, CommitCommand.Assembly()),
        (DownloadCommand.self, DownloadCommand.Assembly()),
        (ExportCommand.self, ExportCommand.Assembly()),
        (ImportCommand.self, ImportCommand.Assembly()),
        (InspectCommand.self, InspectCommand.Assembly()),
        (ImagesCommand.self, ImagesCommand.Assembly()),
        (PsCommand.self, PsCommand.Assembly()),
        (RmCommand.self, RmCommand.Assembly()),
        (RmiCommand.self, RmiCommand.Assembly()),
        (RunCommand.self, RunCommand.Assembly()),
        (StartCommand.self, StartCommand.Assembly()),
        (VersionCommand.self, VersionCommand.Assembly()),
    ]
}

extension Command {
    var resolver: Resolver {
        Assembler(container: DefaultContainer())
            .assemble(commonAssemblies)
            .assemble(commandAssemblies)
            .assemble(coreAssemblies)
            .resolver()
    }

    // MARK: - Assemblies

    private var commonAssemblies: [Assembly] {
        [
            CommonAssembly(),
        ]
    }

    private var commandAssemblies: [Assembly] {
        Setup.allSubcommands.map(\.1)
    }

    private var coreAssemblies: [Assembly] {
        [
            CoreAssembly(),
        ]
    }
}

extension ParsableCommand {
    static var allSubcommands: [ParsableCommand.Type] {
        Setup.allSubcommands.map(\.0)
    }
}
