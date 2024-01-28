import Cocoa
import Darwin
import Foundation
import SwiftUI
import Virtualization

final class MacOSWindowAppLauncher {
    func launchWindow(with vm: VM, bundle: VMBundle) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)

        MacOSWindowApp.vm = vm
        MacOSWindowApp.bundle = bundle
        MacOSWindowApp.main()
    }
}

private struct MacOSWindowApp: App {
    static var vm: VM!
    static var bundle: VMBundle!

    @NSApplicationDelegateAdaptor
    private var appDelegate: MacOSWindowAppDelegate

    var body: some Scene {
        WindowGroup(MacOSWindowApp.vm.metadata.name ?? MacOSWindowApp.vm.metadata.id.description) {
            Group {
                MacOSWindowAppViewView(vm: MacOSWindowApp.vm).onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }.onDisappear {
                    MacOSWindowApp.vm.exit(machineStateURL: MacOSWindowApp.bundle.machineState.asURL, exit: exit)
                }
            }.frame(
                minWidth: CGFloat(VMConfig.DisplayConfig.minWidth),
                idealWidth: CGFloat(MacOSWindowApp.vm.config.display.width),
                maxWidth: .infinity,
                minHeight: CGFloat(VMConfig.DisplayConfig.minHeight),
                idealHeight: CGFloat(MacOSWindowApp.vm.config.display.height),
                maxHeight: .infinity
            )
        }.commands {
            CommandGroup(replacing: .help, addition: {})
            CommandGroup(replacing: .newItem, addition: {})
            CommandGroup(replacing: .pasteboard, addition: {})
            CommandGroup(replacing: .textEditing, addition: {})
            CommandGroup(replacing: .undoRedo, addition: {})
            CommandGroup(replacing: .windowSize, addition: {})
        }
    }
}

private final class MacOSWindowAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let indexOfEditMenu = 2

    func applicationDidFinishLaunching(_: Notification) {
        NSApplication.shared.mainMenu?.removeItem(at: indexOfEditMenu)
    }
}

private struct MacOSWindowAppViewView: NSViewRepresentable {
    typealias NSViewType = VZVirtualMachineView

    private var vm: VM

    init(vm: VM) {
        self.vm = vm
    }

    func makeNSView(context _: Context) -> NSViewType {
        let machineView = VZVirtualMachineView()
        machineView.capturesSystemKeys = false
        if #available(macOS 14.0, *) {
            machineView.automaticallyReconfiguresDisplay = true
        }
        return machineView
    }

    func updateNSView(_ nsView: NSViewType, context _: Context) {
        nsView.virtualMachine = vm.virtualMachine
    }
}
