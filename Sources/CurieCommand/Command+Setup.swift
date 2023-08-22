import ArgumentParser
import CurieCommon
import CurieCore
import Foundation

private enum Setup {
    static let allSubcommands: [(ParsableCommand.Type, Assembly)] = [
        (VersionCommand.self, VersionCommand.Assembly()),
        (RunCommand.self, RunCommand.Assembly()),
        (CreateCommand.self, CreateCommand.Assembly()),
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
