import Foundation
import Testing
@testable import Broom

@Suite("LaunchServicesManager")
struct LaunchServicesManagerTests {
    @Test func unregisterReturnsGracefullyForInvalidPath() {
        let manager = LaunchServicesManager()
        let bogusPath = URL(fileURLWithPath: "/tmp/NonExistent-\(UUID().uuidString).app")
        let result = manager.unregisterApp(at: bogusPath)
        // Should not crash; result may be true or false depending on OS behavior
        _ = result
    }

    @Test func refreshDatabaseDoesNotThrow() {
        let manager = LaunchServicesManager()
        let result = manager.refreshDatabase()
        _ = result
    }
}

@Suite("LoginItemManager")
struct LoginItemManagerTests {
    @Test func unloadLaunchAgentReturnsGracefullyForInvalidPath() {
        let manager = LoginItemManager()
        let bogusPath = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).plist")
        let result = manager.unloadLaunchAgent(at: bogusPath)
        _ = result // Should not crash regardless of return value
    }

    @Test func unloadLaunchDaemonReturnsGracefullyForInvalidPath() {
        let manager = LoginItemManager()
        let bogusPath = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).plist")
        let result = manager.unloadLaunchDaemon(at: bogusPath)
        _ = result // Should not crash regardless of return value
    }

    @Test func removeLoginItemsReturnsEmptyForUnknownBundleID() {
        let manager = LoginItemManager()
        let results = manager.removeLoginItems(matching: "com.nonexistent.\(UUID().uuidString)")
        #expect(results.isEmpty)
    }
}

@Suite("AppUninstaller Metadata Cleanup")
struct AppUninstallerMetadataCleanupTests {
    @Test func metadataCleanupFailuresDoNotAbortUninstall() async {
        let app = InstalledApp(
            name: "TestApp",
            bundleIdentifier: "com.test.metadatacleanup",
            bundlePath: URL(fileURLWithPath: "/tmp/TestApp-\(UUID().uuidString).app"),
            bundleSize: 100
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [
                CleanableItem(
                    path: URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString)"),
                    name: "support-file",
                    size: 50,
                    source: .userData
                ),
            ],
            totalSize: 50,
            isRunning: false,
            isProtected: false
        )

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        var gotComplete = false
        var phases: [UninstallPhase] = []

        for await progress in uninstaller.executeUninstall(plan: plan, moveToTrash: false) {
            switch progress {
            case .phase(let phase):
                phases.append(phase)
            case .complete:
                gotComplete = true
            case .progress:
                break
            }
        }

        #expect(gotComplete)
        #expect(phases.contains(.cleaningMetadata))
        #expect(phases.contains(.refreshingDatabase))
    }

    @Test func protectedAppsSkipMetadataCleanup() async {
        let app = InstalledApp(
            name: "SystemApp",
            bundleIdentifier: "com.apple.systemapp",
            bundlePath: URL(fileURLWithPath: "/System/Applications/SystemApp.app"),
            bundleSize: 100,
            isSystemApp: true,
            isAppleApp: true
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [
                CleanableItem(
                    path: URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString)"),
                    name: "system-support",
                    size: 50,
                    source: .userData
                ),
            ],
            totalSize: 50,
            isRunning: false,
            isProtected: true
        )

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        var phases: [UninstallPhase] = []
        var gotComplete = false

        for await progress in uninstaller.executeUninstall(plan: plan, moveToTrash: false) {
            switch progress {
            case .phase(let phase):
                phases.append(phase)
            case .complete:
                gotComplete = true
            case .progress:
                break
            }
        }

        #expect(gotComplete)
        #expect(!phases.contains(.unloadingLaunchItems))
        #expect(!phases.contains(.removingLoginItems))
        #expect(!phases.contains(.cleaningMetadata))
        #expect(!phases.contains(.refreshingDatabase))
    }

    @Test func appBundleIsDeletedLast() async {
        let bundlePath = URL(fileURLWithPath: "/tmp/DeleteOrder-\(UUID().uuidString).app")
        let supportPath = URL(fileURLWithPath: "/tmp/support-\(UUID().uuidString)")
        let cachePath = URL(fileURLWithPath: "/tmp/cache-\(UUID().uuidString)")

        let app = InstalledApp(
            name: "DeleteOrder",
            bundleIdentifier: "com.test.deleteorder",
            bundlePath: bundlePath,
            bundleSize: 100
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [
                CleanableItem(path: bundlePath, name: "DeleteOrder.app", size: 100, source: .appBundle),
                CleanableItem(path: supportPath, name: "Support", size: 50, source: .userData),
                CleanableItem(path: cachePath, name: "Cache", size: 30, source: .caches),
            ],
            totalSize: 180,
            isRunning: false,
            isProtected: false
        )

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        var deletedPaths: [String] = []

        for await progress in uninstaller.executeUninstall(plan: plan, moveToTrash: false) {
            if case .progress(_, _, let path) = progress {
                deletedPaths.append(path)
            }
        }

        // App bundle items should come after all non-bundle items
        guard let bundleIndex = deletedPaths.firstIndex(of: "DeleteOrder.app") else {
            Issue.record("Bundle item not found in progress")
            return
        }
        let nonBundleNames = ["Support", "Cache"]
        for name in nonBundleNames {
            if let idx = deletedPaths.firstIndex(of: name) {
                #expect(idx < bundleIndex, "\(name) should be deleted before app bundle")
            }
        }
    }

    @Test func executeUninstallEmitsPhaseEventsForNonProtectedApp() async {
        let app = InstalledApp(
            name: "PhaseTest",
            bundleIdentifier: "com.test.phases",
            bundlePath: URL(fileURLWithPath: "/tmp/PhaseTest-\(UUID().uuidString).app"),
            bundleSize: 100
        )
        let launchItem = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/com.test.phases.plist"),
            name: "Launch Agents/com.test.phases.plist",
            size: 10,
            source: .launchItems
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [launchItem],
            totalSize: 10,
            isRunning: false,
            isProtected: false
        )

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        var phases: [UninstallPhase] = []

        for await progress in uninstaller.executeUninstall(plan: plan, moveToTrash: false) {
            if case .phase(let phase) = progress {
                phases.append(phase)
            }
        }

        #expect(phases.contains(.unloadingLaunchItems))
        #expect(phases.contains(.removingLoginItems))
        #expect(phases.contains(.deletingFiles))
        #expect(phases.contains(.cleaningMetadata))
        #expect(phases.contains(.refreshingDatabase))
    }

    @MainActor
    @Test func phaseDescriptionsAreNonEmpty() {
        let allPhases: [UninstallPhase] = [
            .unloadingLaunchItems, .removingLoginItems,
            .deletingFiles, .cleaningMetadata, .refreshingDatabase,
        ]
        for phase in allPhases {
            let desc = UninstallerViewModel.phaseDescription(phase)
            #expect(!desc.isEmpty)
        }
    }
}
