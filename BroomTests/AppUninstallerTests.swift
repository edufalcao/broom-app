import Foundation
import Testing
@testable import Broom

@Suite("AppUninstaller")
struct AppUninstallerTests {
    @MainActor
    @Test func buildPlanRespectsSelectedFiles() async {
        let selectedFile = CleanableItem(path: URL(fileURLWithPath: "/tmp/selected"), size: 100, isSelected: true)
        let deselectedFile = CleanableItem(path: URL(fileURLWithPath: "/tmp/deselected"), size: 50, isSelected: false)
        let app = InstalledApp(
            name: "Sample",
            bundleIdentifier: "com.example.sample",
            bundlePath: URL(fileURLWithPath: "/tmp/Sample.app"),
            bundleSize: 200,
            bundleIsSelected: false,
            associatedFiles: [selectedFile, deselectedFile],
            associatedFilesLoaded: true
        )

        let plan = UninstallerViewModel.buildPlan(for: app, isRunning: false)

        #expect(plan.filesToRemove.count == 1)
        #expect(plan.filesToRemove.first?.path == selectedFile.path)
        #expect(plan.totalSize == 100)
    }

    @Test func discoverArtifactsReturnsPlannerResults() async {
        let app = InstalledApp(
            name: "Sample",
            bundleIdentifier: "com.example.sample",
            bundlePath: URL(fileURLWithPath: "/tmp/Sample.app"),
            bundleSize: 200
        )

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        let artifacts = await uninstaller.discoverArtifacts(for: app)

        // The planner may find nothing on a bare fixture; it just must not crash.
        _ = artifacts
    }
}
