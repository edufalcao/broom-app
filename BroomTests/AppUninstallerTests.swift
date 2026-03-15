import Foundation
import Testing
@testable import Broom

@Suite("AppUninstaller")
struct AppUninstallerTests {
    @Test func prepareUninstallRespectsSelectedFiles() async {
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

        let uninstaller = AppUninstaller(appInventory: MockAppInventory())
        let plan = await uninstaller.prepareUninstall(app: app)

        #expect(plan.filesToRemove.count == 1)
        #expect(plan.filesToRemove.first?.path == selectedFile.path)
        #expect(plan.totalSize == 100)
    }
}
