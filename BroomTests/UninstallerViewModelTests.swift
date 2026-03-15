import Foundation
import Testing
@testable import Broom

@Suite("UninstallerViewModel")
struct UninstallerViewModelTests {
    @MainActor
    @Test func handleAppDropLoadsExternalAppAndShowsPreview() async throws {
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
}
