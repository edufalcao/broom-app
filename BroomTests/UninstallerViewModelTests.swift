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

        let inventory = MockAppInventory(droppedApps: [appURL: droppedApp])
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: MockAppUninstaller(),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults)
            }
        )

        viewModel.handleAppDrop(url: appURL)
        await TestSupport.awaitCondition { viewModel.selectedApp?.bundlePath == appURL }
        await TestSupport.awaitCondition { viewModel.showUninstallConfirmation }

        #expect(viewModel.selectedApp?.name == "Dropped")
        // Plan = selected bundle + selected support files, exactly as shown.
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
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: MockAppUninstaller()
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
        let viewModel = UninstallerViewModel(
            appInventory: MockAppInventory(apps: [app]),
            appUninstaller: MockAppUninstaller(),
            runningAppController: RunningAppController(
                isRunning: { _ in true },
                terminate: { _ in false },
                forceTerminate: { _ in true }
            )
        )

        viewModel.uninstallPlan = UninstallPlan(app: app, filesToRemove: [CleanableItem(path: app.bundlePath, name: "Running.app", size: 10)], totalSize: 10, isRunning: true, isProtected: false)
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
        let viewModel = UninstallerViewModel(
            appInventory: MockAppInventory(apps: [app]),
            appUninstaller: MockAppUninstaller(),
            runningAppController: RunningAppController(
                isRunning: { _ in false },
                terminate: { _ in true },
                forceTerminate: { _ in true }
            )
        )

        viewModel.uninstallPlan = UninstallPlan(app: app, filesToRemove: [CleanableItem(path: app.bundlePath, name: "Running.app", size: 10)], totalSize: 10, isRunning: true, isProtected: false)
        viewModel.showForceQuitAlert = true
        viewModel.forceQuitAndUninstall()
        await TestSupport.awaitCondition { viewModel.showUninstallConfirmation }

        #expect(viewModel.showForceQuitAlert == false)
        #expect(viewModel.showUninstallConfirmation == true)
    }

    @MainActor
    @Test func prepareUninstallMergesDiscoveredArtifactsIntoEditablePlan() async {
        let app = InstalledApp(
            name: "Sample",
            bundleIdentifier: "com.example.sample",
            bundlePath: URL(fileURLWithPath: "/tmp/Sample.app"),
            bundleSize: 200,
            associatedFilesLoaded: true
        )
        let discovered = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/Library/Caches/com.example.sample"),
            size: 50,
            source: .caches
        )
        let inventory = MockAppInventory(apps: [app])
        let uninstaller = MockAppUninstaller(discoveredArtifacts: [discovered])
        let viewModel = UninstallerViewModel(
            appInventory: inventory,
            appUninstaller: uninstaller,
            runningAppController: RunningAppController(
                isRunning: { _ in false },
                terminate: { _ in false },
                forceTerminate: { _ in false }
            )
        )
        viewModel.selectedApp = app

        viewModel.prepareUninstall()
        await TestSupport.awaitCondition { viewModel.showUninstallConfirmation }

        // Discovered artifacts are surfaced in the editable detail list…
        let updated = viewModel.selectedApp
        #expect(updated?.associatedFiles.contains(where: { $0.id == discovered.id }) == true)

        // …and the plan matches exactly the visible selection.
        let plan = viewModel.uninstallPlan
        #expect(plan?.filesToRemove.count == 2)
        #expect(plan?.totalSize == 250)
        #expect(plan?.isRunning == false)
    }
}
