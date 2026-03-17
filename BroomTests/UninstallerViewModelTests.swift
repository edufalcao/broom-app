import Foundation
import Testing
@testable import Broom

@Suite("UninstallerViewModel")
struct UninstallerViewModelTests {
    @MainActor
    @Test func startsInIdleState() {
        let viewModel = UninstallerViewModel(
            appInventory: MockAppInventory(),
            appUninstaller: MockAppUninstaller()
        )
        #expect(viewModel.state == .idle)
    }

    @MainActor
    @Test func scanAppsTransitionsFromIdleToReady() async {
        let app = InstalledApp(
            name: "Test",
            bundleIdentifier: "com.test.app",
            bundlePath: URL(fileURLWithPath: "/tmp/Test.app")
        )
        let inventory = MockAppInventory(apps: [app])
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: MockAppUninstaller()
        )

        #expect(viewModel.state == .idle)
        viewModel.scanApps()
        await TestSupport.awaitCondition { viewModel.state == .ready }

        #expect(viewModel.apps.count == 1)
        #expect(viewModel.apps.first?.name == "Test")
    }

    @MainActor
    @Test func appDropFromIdleTransitionsToReady() async throws {
        let appURL = URL(fileURLWithPath: "/tmp/Dropped.app")
        let droppedApp = InstalledApp(
            name: "Dropped",
            bundleIdentifier: "com.example.dropped",
            bundlePath: appURL,
            bundleSize: 200,
            associatedFiles: [
                CleanableItem(path: URL(fileURLWithPath: "/tmp/support"), size: 100),
            ],
            associatedFilesLoaded: true
        )
        let plan = UninstallPlan(
            app: droppedApp,
            filesToRemove: [
                CleanableItem(path: appURL, name: "Dropped.app", size: 200),
                CleanableItem(path: URL(fileURLWithPath: "/tmp/support"), size: 100),
            ],
            totalSize: 300,
            isRunning: false,
            isProtected: false
        )

        let inventory = MockAppInventory(droppedApps: [appURL: droppedApp])
        let uninstaller = MockAppUninstaller(preparedPlan: plan)
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: uninstaller,
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults)
            }
        )

        viewModel.handleAppDrop(url: appURL)
        await TestSupport.awaitCondition { viewModel.selectedApp?.bundlePath == appURL }
        await TestSupport.awaitCondition { viewModel.showUninstallConfirmation }

        #expect(viewModel.selectedApp?.name == "Dropped")
        #expect(viewModel.uninstallPlan?.totalSize == 300)
    }

    @MainActor
    @Test func filteredAppsExcludeFrameworkBundledSystemApps() async {
        let wish = InstalledApp(
            name: "Wish",
            bundleIdentifier: "com.tcltk.wish",
            bundlePath: URL(
                fileURLWithPath: "/System/Library/Frameworks/Tk.framework/Versions/8.5/Resources/Wish.app"
            ),
            isSystemApp: true
        )
        let regular = InstalledApp(
            name: "Regular",
            bundleIdentifier: "com.example.regular",
            bundlePath: URL(fileURLWithPath: "/Applications/Regular.app")
        )
        let inventory = MockAppInventory(apps: [wish, regular])
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: MockAppUninstaller()
        )

        viewModel.scanApps()
        await TestSupport.awaitCondition { viewModel.state == .ready }

        #expect(viewModel.filteredApps.count == 1)
        #expect(viewModel.filteredApps.first?.bundleIdentifier == "com.example.regular")
    }

    @MainActor
    @Test func togglesSelectedFilesBeforePreparingUninstall() async {
        let file = CleanableItem(path: URL(fileURLWithPath: "/tmp/support"), size: 100)
        var app = InstalledApp(
            name: "Sample",
            bundleIdentifier: "com.example.sample",
            bundlePath: URL(fileURLWithPath: "/tmp/Sample.app"),
            bundleSize: 200,
            associatedFiles: [file],
            associatedFilesLoaded: true
        )
        let inventory = MockAppInventory(apps: [app])
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [file],
            totalSize: 100,
            isRunning: false,
            isProtected: false
        )
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: MockAppUninstaller(preparedPlan: plan)
        )

        viewModel.selectedApp = app
        viewModel.toggleBundleSelection()
        viewModel.toggleAssociatedFile(file.id)

        #expect(viewModel.selectedApp?.bundleIsSelected == false)
        #expect(viewModel.selectedApp?.associatedFiles.first?.isSelected == false)

        app.bundleIsSelected = false
        app.associatedFiles[0].isSelected = false
        #expect(viewModel.selectedApp?.selectedItemCount == 0)
    }

    @MainActor
    @Test func showsForceQuitFallbackWhenGracefulQuitFails() async {
        let app = InstalledApp(
            name: "Running",
            bundleIdentifier: "com.example.running",
            bundlePath: URL(fileURLWithPath: "/tmp/Running.app")
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [
                CleanableItem(path: app.bundlePath, name: "Running.app", size: 10),
            ],
            totalSize: 10,
            isRunning: true,
            isProtected: false
        )

        let viewModel = UninstallerViewModel(
            appInventory: MockAppInventory(apps: [app]),
            appUninstaller: MockAppUninstaller(preparedPlan: plan),
            runningAppController: RunningAppController(
                isRunning: { _ in true },
                terminate: { _ in false },
                forceTerminate: { _ in true }
            )
        )

        viewModel.uninstallPlan = plan
        viewModel.showRunningAppAlert = true
        viewModel.quitAndUninstall()

        #expect(viewModel.showRunningAppAlert == false)
        #expect(viewModel.showForceQuitAlert == true)
    }

    @MainActor
    @Test func forceQuitProceedsToConfirmationWhenAppStopsRunning() async {
        let app = InstalledApp(
            name: "Running",
            bundleIdentifier: "com.example.running",
            bundlePath: URL(fileURLWithPath: "/tmp/Running.app")
        )
        let plan = UninstallPlan(
            app: app,
            filesToRemove: [
                CleanableItem(path: app.bundlePath, name: "Running.app", size: 10),
            ],
            totalSize: 10,
            isRunning: true,
            isProtected: false
        )

        let viewModel = UninstallerViewModel(
            appInventory: MockAppInventory(apps: [app]),
            appUninstaller: MockAppUninstaller(preparedPlan: plan),
            runningAppController: RunningAppController(
                isRunning: { _ in false },
                terminate: { _ in true },
                forceTerminate: { _ in true }
            )
        )

        viewModel.uninstallPlan = plan
        viewModel.showForceQuitAlert = true
        viewModel.forceQuitAndUninstall()
        await TestSupport.awaitCondition { viewModel.showUninstallConfirmation }

        #expect(viewModel.showForceQuitAlert == false)
        #expect(viewModel.showUninstallConfirmation == true)
    }
}
