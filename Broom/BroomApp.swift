import SwiftUI

@main
struct BroomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Broom", id: "main") {
            MainWindow()
        }
        .defaultSize(width: 750, height: 520)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan System") {
                    NotificationCenter.default.post(name: .startScan, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(after: .sidebar) {
                Button("System Cleaner") {
                    NotificationCenter.default.post(name: .switchToCleanerSection, object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("App Uninstaller") {
                    NotificationCenter.default.post(name: .switchToUninstallerSection, object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.requestPermission()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle .app files dropped on Dock icon
        for url in urls where url.pathExtension == "app" {
            NotificationCenter.default.post(name: .appDroppedOnDock, object: url)
        }
    }
}

extension Notification.Name {
    static let startScan = Notification.Name("com.broom.startScan")
    static let appDroppedOnDock = Notification.Name("com.broom.appDroppedOnDock")
    static let switchToCleanerSection = Notification.Name("com.broom.switchToCleanerSection")
    static let switchToUninstallerSection = Notification.Name("com.broom.switchToUninstallerSection")
}
