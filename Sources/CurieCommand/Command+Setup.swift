import ArgumentParser
import CurieCommon
import CurieCore
import CurieCRI
import Foundation

private enum Setup {
    static let allSubcommands: [(ParsableCommand.Type, Assembly)] = [
        (BuildCommand.self, BuildCommand.Assembly()),
        (CloneCommand.self, CloneCommand.Assembly()),
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
        (ServeCommand.self, ServeCommand.Assembly()),
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
            .assemble(criAssemblies)
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

    private var criAssemblies: [Assembly] {
        [
            CRIAssembly(),
        ]
    }
}

extension ParsableCommand {
    static var allSubcommands: [ParsableCommand.Type] {
        Setup.allSubcommands.map(\.0)
    }
}
