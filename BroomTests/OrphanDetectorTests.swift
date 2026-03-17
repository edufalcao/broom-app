import Foundation
import Testing
@testable import Broom

@Suite("OrphanDetector")
struct OrphanDetectorTests {

    // MARK: - Helper

    /// Creates a standard detector with the given parameters.
    /// By default, the stale-age is set to 0 so newly created test files
    /// are not suppressed by the modification-date gate.
    private func makeDetector(
        root: URL,
        bundleIdentifiers: Set<String> = [],
        snapshot: InstalledAppSnapshot? = nil,
        subdirectories: [URL],
        receiptsDirectory: URL? = nil,
        safeListURL: URL? = nil,
        orphanStaleAgeDays: Int = 0
    ) -> OrphanDetector {
        let snap = snapshot ?? InstalledAppSnapshot(
            installedBundleIDs: bundleIdentifiers,
            installedAppURLs: [],
            runningBundleIDs: [],
            launchItemLabels: []
        )
        let receipts = receiptsDirectory ?? root.appendingPathComponent("receipts")
        let safeList = safeListURL ?? root.appendingPathComponent("missing.json")

        return OrphanDetector(
            appInventory: MockAppInventory(
                bundleIdentifiers: bundleIdentifiers,
                snapshot: snap
            ),
            locations: OrphanDetectorLocations(
                librarySubdirectories: subdirectories,
                receiptsDirectory: receipts
            ),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                defaults.set(orphanStaleAgeDays, forKey: "orphanStaleAgeDays")
                return AppPreferences(userDefaults: defaults, safeListURL: safeList)
            }
        )
    }

    /// Date in the past, well beyond the default stale-age threshold.
    private var oldDate: Date {
        Calendar.current.date(byAdding: .day, value: -90, to: Date())!
    }

    // MARK: - Basic Detection

    @Test func detectsOrphansAndAssignsHighConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let applicationSupport = root.appendingPathComponent("Application Support")
        let savedState = root.appendingPathComponent("Saved Application State")
        try FileManager.default.createDirectory(at: applicationSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: savedState, withIntermediateDirectories: true)

        try TestSupport.writeOrphanFile(at: applicationSupport.appendingPathComponent("com.example.oldapp/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: applicationSupport.appendingPathComponent("com.example.oldapp"))
        try TestSupport.writeOrphanFile(at: savedState.appendingPathComponent("com.example.oldapp.savedState/state.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: savedState.appendingPathComponent("com.example.oldapp.savedState"))

        let detector = makeDetector(
            root: root,
            bundleIdentifiers: ["com.example.installed"],
            subdirectories: [applicationSupport, savedState]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.appName == "oldapp")
        #expect(orphans.first?.confidence == .high)
        #expect(orphans.first?.locationCount == 2)
    }

    @Test func excludesProtectedAndSafeListedEntries() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        let appleCache = caches.appendingPathComponent("com.apple.Safari")
        let safeCache = caches.appendingPathComponent("com.example.safe")
        try TestSupport.writeOrphanFile(at: appleCache.appendingPathComponent("cache.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appleCache)
        try TestSupport.writeOrphanFile(at: safeCache.appendingPathComponent("cache.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: safeCache)

        let safeListURL = root.appendingPathComponent("safelist.json")
        let data = try JSONEncoder().encode([safeCache.path])
        try data.write(to: safeListURL)

        let detector = makeDetector(
            root: root,
            subdirectories: [caches],
            safeListURL: safeListURL
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func receiptDatabaseBoostsConfidenceToHigh() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.removed.app/cache.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: caches.appendingPathComponent("com.removed.app"))

        let receiptsDir = root.appendingPathComponent("receipts")
        try FileManager.default.createDirectory(at: receiptsDir, withIntermediateDirectories: true)

        let receiptPlist: [String: Any] = [
            "PackageIdentifier": "com.removed.app",
            "InstallDate": Date(),
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: receiptPlist, format: .xml, options: 0)
        try plistData.write(to: receiptsDir.appendingPathComponent("com.removed.app.plist"))

        let detector = makeDetector(
            root: root,
            subdirectories: [caches],
            receiptsDirectory: receiptsDir
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .high)
    }

    @Test func bundleIDPatternWithoutReceiptOrSavedStateIsMedium() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.example.unknownapp/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.example.unknownapp"))

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .medium)
    }

    @Test func plainNameWithoutBundleIDPatternIsFiltered() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Plain name entries (no bundle ID pattern) should now be suppressed
        // by the pattern gate — they are low-signal heuristics
        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("SomeRandomApp/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("SomeRandomApp"))

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport]
        )

        let orphans = await detector.detectOrphans()
        // Plain names are now filtered out by the pattern gate
        #expect(orphans.isEmpty)
    }

    @Test func emptyReceiptsDirectoryDoesNotCrash() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.test.orphan/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: caches.appendingPathComponent("com.test.orphan"))

        let detector = makeDetector(
            root: root,
            subdirectories: [caches]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
    }

    @Test func skipsEmptyDirectories() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        let emptyDir = caches.appendingPathComponent("com.empty.app")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let detector = makeDetector(
            root: root,
            subdirectories: [caches]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    // MARK: - Phase 2: Suppression Tests

    @Test func recentlyModifiedFilesAreSuppressed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        // Write a file that was modified "now" — within stale-age threshold
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.recent.app/data.dat"))
        // Don't set old modification date — it will be "now"

        let detector = makeDetector(
            root: root,
            subdirectories: [caches],
            orphanStaleAgeDays: 30  // candidates modified in last 30 days suppressed
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func staleAgeThresholdWorksCorrectly() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        // File modified 60 days ago — beyond the 30-day threshold
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.stale.app/data.dat"), modificationDate: sixtyDaysAgo)
        try TestSupport.setModificationDate(sixtyDaysAgo, at: caches.appendingPathComponent("com.stale.app"))

        // File modified 10 days ago — within the 30-day threshold
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.fresh.app/data.dat"), modificationDate: tenDaysAgo)
        try TestSupport.setModificationDate(tenDaysAgo, at: caches.appendingPathComponent("com.fresh.app"))

        let detector = makeDetector(
            root: root,
            subdirectories: [caches],
            orphanStaleAgeDays: 30
        )

        let orphans = await detector.detectOrphans()
        // Only the 60-day-old candidate should survive
        #expect(orphans.count == 1)
        #expect(orphans.first?.bundleIdentifier == "com.stale.app")
    }

    @Test func recentDescendantActivitySuppressesOldParentDirectory() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        let candidate = appSupport.appendingPathComponent("com.example.activecache")
        let recentDate = Date()
        try TestSupport.writeOrphanFile(
            at: candidate.appendingPathComponent("nested/live.sqlite-wal"),
            modificationDate: recentDate
        )
        try TestSupport.setModificationDate(oldDate, at: candidate)

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport],
            orphanStaleAgeDays: 30
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func runningAppsAreSuppressed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.running.app/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: caches.appendingPathComponent("com.running.app"))

        let snapshot = InstalledAppSnapshot(
            installedBundleIDs: [],
            installedAppURLs: [],
            runningBundleIDs: ["com.running.app"],
            launchItemLabels: []
        )

        let detector = makeDetector(
            root: root,
            snapshot: snapshot,
            subdirectories: [caches]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func installedAppMatchesSuppressCandidates() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.installed.app/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.installed.app"))

        // Simulate Caskroom/Setapp install — the snapshot contains this bundle ID
        let snapshot = InstalledAppSnapshot(
            installedBundleIDs: ["com.installed.app"],
            installedAppURLs: [],
            runningBundleIDs: [],
            launchItemLabels: []
        )

        let detector = makeDetector(
            root: root,
            bundleIdentifiers: ["com.installed.app"],
            snapshot: snapshot,
            subdirectories: [appSupport]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func managedContainerCreatorSuppressesMigratedTeamsContainer() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let groupContainers = root.appendingPathComponent("Group Containers")
        let teamsContainer = groupContainers.appendingPathComponent("UBF8T346G9.com.microsoft.teams")
        try FileManager.default.createDirectory(at: teamsContainer, withIntermediateDirectories: true)

        try TestSupport.writeOrphanFile(
            at: teamsContainer.appendingPathComponent("Library/Application Support/Logs/MSTeams.log"),
            modificationDate: oldDate
        )
        try TestSupport.setModificationDate(oldDate, at: teamsContainer)

        let metadata: [String: Any] = [
            "MCMMetadataCreator": "com.microsoft.teams2",
            "MCMMetadataIdentifier": "UBF8T346G9.com.microsoft.teams",
        ]
        let metadataData = try PropertyListSerialization.data(
            fromPropertyList: metadata,
            format: .xml,
            options: 0
        )
        try metadataData.write(
            to: teamsContainer.appendingPathComponent(".com.apple.containermanagerd.metadata.plist")
        )

        let snapshot = InstalledAppSnapshot(
            installedBundleIDs: ["com.microsoft.teams2"],
            installedAppURLs: [],
            runningBundleIDs: [],
            launchItemLabels: []
        )

        let detector = makeDetector(
            root: root,
            snapshot: snapshot,
            subdirectories: [groupContainers]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func lowSignalNameOnlyLeftoversNotListed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Plain app name — not a reverse-DNS pattern
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("MyAppData/file.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("MyAppData"))

        // Single-dot name — not a reverse-DNS pattern
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("company.app/file.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("company.app"))

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func protectedDataFamiliesNeverListedInGenericOrphanScan() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Password manager
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.agilebits.onepassword7/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.agilebits.onepassword7"))

        // VPN tool
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("net.mullvad.vpn/config.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("net.mullvad.vpn"))

        // AI assistant
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.openai.chatgpt/models.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.openai.chatgpt"))

        // Automation tool
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.raycast.macos/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.raycast.macos"))

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func appleAccountPreferenceFilesAreSuppressed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let preferences = root.appendingPathComponent("Preferences")
        try FileManager.default.createDirectory(at: preferences, withIntermediateDirectories: true)

        let mobileMeAccounts = preferences.appendingPathComponent("MobileMeAccounts.plist")
        try TestSupport.writeFile(at: mobileMeAccounts, contents: "<plist/>")
        try TestSupport.setModificationDate(oldDate, at: mobileMeAccounts)

        let detector = makeDetector(
            root: root,
            subdirectories: [preferences]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func appleManagedGroupContainersAreSuppressed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let groupContainers = root.appendingPathComponent("Group Containers")
        try FileManager.default.createDirectory(at: groupContainers, withIntermediateDirectories: true)

        let storeKitContainer = groupContainers.appendingPathComponent("group.com.apple.storekit")
        try TestSupport.writeOrphanFile(
            at: storeKitContainer.appendingPathComponent("cache.dat"),
            modificationDate: oldDate
        )
        try TestSupport.setModificationDate(oldDate, at: storeKitContainer)

        let detector = makeDetector(
            root: root,
            subdirectories: [groupContainers]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func candidatesBelowMinimumSizeAreSuppressed() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        // Create a directory with no files inside (0 bytes total size).
        // This is below the 4KB minimum size threshold.
        let emptyDir = caches.appendingPathComponent("com.tiny.app")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        try TestSupport.setModificationDate(oldDate, at: emptyDir)

        // Also create a normal-sized orphan for contrast
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.normal.app/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: caches.appendingPathComponent("com.normal.app"))

        let detector = makeDetector(
            root: root,
            subdirectories: [caches]
        )

        let orphans = await detector.detectOrphans()
        // Only the normal-sized candidate should appear; the empty one is suppressed
        #expect(orphans.count == 1)
        #expect(orphans.first?.bundleIdentifier == "com.normal.app")
    }

    @Test func candidatesSurvivingAllChecksProperlyListedWithConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let appSupport = root.appendingPathComponent("Application Support")
        let savedState = root.appendingPathComponent("Saved Application State")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: savedState, withIntermediateDirectories: true)

        // High confidence: bundle ID pattern + saved state + old enough + large enough
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.old.removedapp/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.old.removedapp"))
        try TestSupport.writeOrphanFile(at: savedState.appendingPathComponent("com.old.removedapp.savedState/state.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: savedState.appendingPathComponent("com.old.removedapp.savedState"))

        // Medium confidence: bundle ID pattern only, no saved state (different app name)
        try TestSupport.writeOrphanFile(at: appSupport.appendingPathComponent("com.another.goneapp/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: appSupport.appendingPathComponent("com.another.goneapp"))

        let detector = makeDetector(
            root: root,
            subdirectories: [appSupport, savedState]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 2)

        let highOrphan = orphans.first { $0.appName == "removedapp" }
        let mediumOrphan = orphans.first { $0.appName == "goneapp" }

        #expect(highOrphan?.confidence == .high)
        #expect(highOrphan?.locationCount == 2)
        #expect(mediumOrphan?.confidence == .medium)
    }

    @Test func containerOnlyCandidatesDefaultToLowConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let groupContainers = root.appendingPathComponent("Group Containers")
        try FileManager.default.createDirectory(at: groupContainers, withIntermediateDirectories: true)

        let avastContainer = groupContainers.appendingPathComponent("6H4HRTU5E3.group.com.avast.osx")
        try TestSupport.writeOrphanFile(
            at: avastContainer.appendingPathComponent("store"),
            modificationDate: oldDate
        )
        try TestSupport.setModificationDate(oldDate, at: avastContainer)

        let detector = makeDetector(
            root: root,
            subdirectories: [groupContainers]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .low)
    }

    @Test func launchItemMatchSuppressesCandidate() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.launch.agent/data.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: caches.appendingPathComponent("com.launch.agent"))

        let snapshot = InstalledAppSnapshot(
            installedBundleIDs: [],
            installedAppURLs: [],
            runningBundleIDs: [],
            launchItemLabels: ["com.launch.agent"]
        )

        let detector = makeDetector(
            root: root,
            snapshot: snapshot,
            subdirectories: [caches]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func savedStatePatternMatchesWithoutBundleID() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let savedState = root.appendingPathComponent("Saved Application State")
        try FileManager.default.createDirectory(at: savedState, withIntermediateDirectories: true)

        // .savedState suffix matches the pattern gate even with only 2 dot-separated parts
        try TestSupport.writeOrphanFile(at: savedState.appendingPathComponent("MyApp.savedState/state.dat"), modificationDate: oldDate)
        try TestSupport.setModificationDate(oldDate, at: savedState.appendingPathComponent("MyApp.savedState"))

        let detector = makeDetector(
            root: root,
            subdirectories: [savedState]
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
    }

    @Test func zeroStaleAgeDaysAllowsRecentFiles() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        // Write a file with current modification date
        try TestSupport.writeOrphanFile(at: caches.appendingPathComponent("com.recent.app/data.dat"))

        let detector = makeDetector(
            root: root,
            subdirectories: [caches],
            orphanStaleAgeDays: 0  // no stale-age suppression
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
    }
}
