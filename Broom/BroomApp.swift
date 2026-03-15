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
            // Replace the default Preferences menu item with our own
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }

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

                Button("Large Files") {
                    NotificationCenter.default.post(name: .switchToLargeFilesSection, object: nil)
                }
                .keyboardShortcut("3", modifiers: [.command])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.requestPermission()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.pathExtension == "app" {
            NotificationCenter.default.post(name: .appDroppedOnDock, object: url)
        }
    }
}

extension Notification.Name {
    static let startScan = Notification.Name("com.broom.startScan")
    static let appDroppedOnDock = Notification.Name("com.broom.appDroppedOnDock")
    static let openSettings = Notification.Name("com.broom.openSettings")
    static let switchToCleanerSection = Notification.Name("com.broom.switchToCleanerSection")
    static let switchToUninstallerSection = Notification.Name("com.broom.switchToUninstallerSection")
    static let switchToLargeFilesSection = Notification.Name("com.broom.switchToLargeFilesSection")
}
