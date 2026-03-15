import Foundation
import Testing
@testable import Broom

@Suite("AppInventory")
struct AppInventoryTests {
    @Test func loadsDroppedAppAndAssociatedFiles() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDirectory = root.appendingPathComponent("Applications")
        try FileManager.default.createDirectory(at: appsDirectory, withIntermediateDirectories: true)
        let appURL = try TestSupport.makeAppBundle(
            at: appsDirectory,
            name: "Sample",
            bundleIdentifier: "com.example.sample"
        )

        let appSupport = root.appendingPathComponent("Library/Application Support")
        let preferences = root.appendingPathComponent("Library/Preferences")
        let launchAgents = root.appendingPathComponent("Library/LaunchAgents")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: preferences, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: launchAgents, withIntermediateDirectories: true)

        try TestSupport.writeFile(at: appSupport.appendingPathComponent("Sample/cache.dat"))
        try TestSupport.writeFile(at: preferences.appendingPathComponent("com.example.sample.plist"))

        let launchAgentURL = launchAgents.appendingPathComponent("com.example.sample.agent.plist")
        let plist: [String: Any] = [
            "Label": "com.example.sample.agent",
            "ProgramArguments": ["/Applications/Sample.app/Contents/MacOS/Sample"],
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: launchAgentURL)

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDirectory],
                librarySearchDirectories: [
                    ("Application Support", appSupport),
                ],
                preferencesDirectory: preferences,
                launchAgentDirectories: [
                    ("Launch Agents", launchAgents),
                ]
            )
        )

        let loadedApp = await inventory.loadApp(at: appURL)
        #expect(loadedApp?.associatedFilesLoaded == true)
        #expect(loadedApp?.associatedFiles.count == 3)
        #expect(loadedApp?.associatedFiles.contains(where: { $0.name.contains("Launch Agents") }) == true)
    }

    @Test func returnsInstalledBundleIdentifiersWithoutLoadingAssociatedFiles() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDirectory = root.appendingPathComponent("Applications")
        try FileManager.default.createDirectory(at: appsDirectory, withIntermediateDirectories: true)
        _ = try TestSupport.makeAppBundle(
            at: appsDirectory,
            name: "Sample",
            bundleIdentifier: "com.example.sample"
        )

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDirectory],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: []
            )
        )

        let identifiers = await inventory.installedBundleIdentifiers()
        #expect(identifiers.contains("com.example.sample"))
    }
}
