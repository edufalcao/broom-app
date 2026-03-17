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
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [
                    ("Application Support", appSupport),
                ],
                preferencesDirectory: preferences,
                launchAgentDirectories: [
                    ("Launch Agents", launchAgents),
                ],
                supplementalApplicationURLsProvider: { [] },
                runningBundleIDsProvider: { [] }
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
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [],
                supplementalApplicationURLsProvider: { [] },
                runningBundleIDsProvider: { [] }
            )
        )

        let identifiers = await inventory.installedBundleIdentifiers()
        #expect(identifiers.contains("com.example.sample"))
    }

    @Test func snapshotDeduplicatesAcrossRoots() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDir = root.appendingPathComponent("Applications")
        let extendedDir = root.appendingPathComponent("Extended")
        try FileManager.default.createDirectory(at: appsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: extendedDir, withIntermediateDirectories: true)

        _ = try TestSupport.makeAppBundle(
            at: appsDir, name: "Dupe", bundleIdentifier: "com.example.dupe"
        )
        _ = try TestSupport.makeAppBundle(
            at: extendedDir, name: "Dupe", bundleIdentifier: "com.example.dupe"
        )

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDir],
                extendedAppDiscoveryRoots: [extendedDir],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [],
                supplementalApplicationURLsProvider: { [] },
                runningBundleIDsProvider: { [] }
            )
        )

        let snapshot = await inventory.buildSnapshot()
        #expect(snapshot.installedBundleIDs.count == 1)
        #expect(snapshot.installedBundleIDs.contains("com.example.dupe"))
    }

    @Test func snapshotIncludesRunningAndLaunchLabels() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDir = root.appendingPathComponent("Applications")
        let launchDir = root.appendingPathComponent("LaunchAgents")
        try FileManager.default.createDirectory(at: appsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: launchDir, withIntermediateDirectories: true)

        _ = try TestSupport.makeAppBundle(
            at: appsDir, name: "Alpha", bundleIdentifier: "com.example.alpha"
        )

        let plist: [String: Any] = ["Label": "com.example.alpha.agent"]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0
        )
        try plistData.write(to: launchDir.appendingPathComponent("com.example.alpha.agent.plist"))

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDir],
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [("Launch Agents", launchDir)],
                supplementalApplicationURLsProvider: { [] },
                runningBundleIDsProvider: { ["com.example.running"] }
            )
        )

        let snapshot = await inventory.buildSnapshot()
        #expect(snapshot.installedBundleIDs.contains("com.example.alpha"))
        #expect(snapshot.runningBundleIDs.contains("com.example.running"))
        #expect(snapshot.launchItemLabels.contains("com.example.alpha.agent"))
    }

    @Test func snapshotIncludesEmbeddedHelperBundleIdentifiers() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDir = root.appendingPathComponent("Applications")
        try FileManager.default.createDirectory(at: appsDir, withIntermediateDirectories: true)

        let hostApp = try TestSupport.makeAppBundle(
            at: appsDir,
            name: "Host",
            bundleIdentifier: "com.example.host"
        )
        _ = try TestSupport.makeAppBundle(
            at: hostApp.appendingPathComponent("Contents/MacOS"),
            name: "Host Helper",
            bundleIdentifier: "com.example.host.helper"
        )

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDir],
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [],
                supplementalApplicationURLsProvider: { [] },
                runningBundleIDsProvider: { [] }
            )
        )

        let snapshot = await inventory.buildSnapshot()
        #expect(snapshot.installedBundleIDs.contains("com.example.host"))
        #expect(snapshot.installedBundleIDs.contains("com.example.host.helper"))
    }

    @Test func classifiesFrameworkBundledSystemAppsAsSystemApps() {
        let wishURL = URL(
            fileURLWithPath: "/System/Library/Frameworks/Tk.framework/Versions/8.5/Resources/Wish.app"
        )

        let classification = AppInventory.classifyApp(
            at: wishURL,
            bundleIdentifier: "com.tcltk.wish"
        )

        #expect(classification.isSystemApp)
        #expect(!classification.isAppleApp)
    }

    @Test func snapshotIncludesSpotlightApps() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDir = root.appendingPathComponent("Applications")
        let externalDir = root.appendingPathComponent("External")
        try FileManager.default.createDirectory(at: appsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: externalDir, withIntermediateDirectories: true)

        let spotlightApp = try TestSupport.makeAppBundle(
            at: externalDir, name: "Spotlight", bundleIdentifier: "com.example.spotlight"
        )

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDir],
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [],
                supplementalApplicationURLsProvider: { [spotlightApp] },
                runningBundleIDsProvider: { [] }
            )
        )

        let snapshot = await inventory.buildSnapshot()
        #expect(snapshot.installedBundleIDs.contains("com.example.spotlight"))
        #expect(snapshot.installedAppURLs.contains(spotlightApp.standardizedFileURL))
    }

    @Test func includesSpotlightSupplementedAppsOutsideStandardDirectories() async throws {
        let root = try TestSupport.makeTempDirectory()
        let appsDirectory = root.appendingPathComponent("Applications")
        let externalDirectory = root.appendingPathComponent("ExternalApps")
        try FileManager.default.createDirectory(at: appsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: externalDirectory, withIntermediateDirectories: true)

        _ = try TestSupport.makeAppBundle(
            at: appsDirectory,
            name: "Standard",
            bundleIdentifier: "com.example.standard"
        )
        let externalApp = try TestSupport.makeAppBundle(
            at: externalDirectory,
            name: "Portable",
            bundleIdentifier: "com.example.portable"
        )

        let inventory = AppInventory(
            locations: AppInventoryLocations(
                applicationDirectories: [appsDirectory],
                extendedAppDiscoveryRoots: [],
                librarySearchDirectories: [],
                preferencesDirectory: root.appendingPathComponent("Preferences"),
                launchAgentDirectories: [],
                supplementalApplicationURLsProvider: { [externalApp] },
                runningBundleIDsProvider: { [] }
            )
        )

        let apps = await inventory.loadAllApps()
        let identifiers = await inventory.installedBundleIdentifiers()

        #expect(apps.count == 2)
        #expect(apps.contains(where: { $0.bundleIdentifier == "com.example.portable" }))
        #expect(identifiers.contains("com.example.portable"))
    }
}
