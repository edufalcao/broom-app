import SwiftUI

enum SidebarSection: String, CaseIterable, Hashable {
    case cleaner = "Clean"
    case uninstaller = "Uninstall"
    case artifacts = "Artifacts"
    case largeFiles = "Large Files"

    var icon: String {
        switch self {
        case .cleaner: return "magnifyingglass"
        case .uninstaller: return "shippingbox"
        case .artifacts: return "archivebox"
        case .largeFiles: return "doc.badge.arrow.up"
        }
    }
}

@Observable
final class AppRouter {
    var selectedSection: SidebarSection? = .cleaner
    var pendingAction: PendingAction?

    enum PendingAction: Equatable {
        case startScan
        case appDropped(URL)
    }
}

@main
struct BroomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Broom", id: "main") {
            MainWindow()
                .environment(appDelegate.router)
        }
        .defaultSize(width: 750, height: 520)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan System") {
                    appDelegate.router.pendingAction = .startScan
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(after: .sidebar) {
                Button("System Cleaner") {
                    appDelegate.router.selectedSection = .cleaner
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("App Uninstaller") {
                    appDelegate.router.selectedSection = .uninstaller
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Large Files") {
                    appDelegate.router.selectedSection = .largeFiles
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Project Artifacts") {
                    appDelegate.router.selectedSection = .artifacts
                }
                .keyboardShortcut("4", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let router = AppRouter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.requestPermission()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.pathExtension == "app" {
            router.pendingAction = .appDropped(url)
        }
    }
}
