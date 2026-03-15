import Foundation
import Testing
@testable import Broom

@Suite("OrphanDetector")
struct OrphanDetectorTests {
    @Test func detectsOrphansAndAssignsHighConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let applicationSupport = root.appendingPathComponent("Application Support")
        let savedState = root.appendingPathComponent("Saved Application State")
        try FileManager.default.createDirectory(at: applicationSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: savedState, withIntermediateDirectories: true)

        try TestSupport.writeFile(at: applicationSupport.appendingPathComponent("com.example.oldapp/data.dat"))
        try TestSupport.writeFile(at: savedState.appendingPathComponent("com.example.oldapp.savedState/state.dat"))

        let inventory = MockAppInventory(bundleIdentifiers: ["com.example.installed"])
        let detector = OrphanDetector(
            appInventory: inventory,
            locations: OrphanDetectorLocations(librarySubdirectories: [applicationSupport, savedState], receiptsDirectory: root.appendingPathComponent("receipts")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
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
        try TestSupport.writeFile(at: appleCache.appendingPathComponent("cache.dat"))
        try TestSupport.writeFile(at: safeCache.appendingPathComponent("cache.dat"))

        let safeListURL = root.appendingPathComponent("safelist.json")
        let data = try JSONEncoder().encode([safeCache.path])
        try data.write(to: safeListURL)

        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [caches], receiptsDirectory: root.appendingPathComponent("receipts")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: safeListURL)
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }

    @Test func receiptDatabaseBoostsConfidenceToHigh() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Create an orphan entry with bundle ID pattern but no saved state
        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try TestSupport.writeFile(at: caches.appendingPathComponent("com.removed.app/cache.dat"))

        // Create a matching receipt in the receipts directory
        let receiptsDir = root.appendingPathComponent("receipts")
        try FileManager.default.createDirectory(at: receiptsDir, withIntermediateDirectories: true)

        let receiptPlist: [String: Any] = [
            "PackageIdentifier": "com.removed.app",
            "InstallDate": Date(),
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: receiptPlist, format: .xml, options: 0)
        try plistData.write(to: receiptsDir.appendingPathComponent("com.removed.app.plist"))

        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [caches], receiptsDirectory: receiptsDir),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .high)
    }

    @Test func bundleIDPatternWithoutReceiptOrSavedStateIsMedium() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Orphan with bundle ID pattern but no saved state and no receipt
        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try TestSupport.writeFile(at: appSupport.appendingPathComponent("com.example.unknownapp/data.dat"))

        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [appSupport], receiptsDirectory: root.appendingPathComponent("empty-receipts")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .medium)
    }

    @Test func plainNameWithoutSignalsIsLowConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Orphan with plain name (no bundle ID pattern)
        let appSupport = root.appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try TestSupport.writeFile(at: appSupport.appendingPathComponent("SomeRandomApp/data.dat"))

        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [appSupport], receiptsDirectory: root.appendingPathComponent("empty-receipts")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        #expect(orphans.first?.confidence == .low)
    }

    @Test func emptyReceiptsDirectoryDoesNotCrash() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try TestSupport.writeFile(at: caches.appendingPathComponent("com.test.orphan/data.dat"))

        // Point receipts to a non-existent directory
        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [caches], receiptsDirectory: root.appendingPathComponent("nonexistent")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.count == 1)
        // Should still work, just without receipt-based confidence boost
    }

    @Test func skipsEmptyDirectories() async throws {
        let root = try TestSupport.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let caches = root.appendingPathComponent("Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)

        // Create an empty directory (0 bytes of file content)
        let emptyDir = caches.appendingPathComponent("com.empty.app")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let detector = OrphanDetector(
            appInventory: MockAppInventory(bundleIdentifiers: []),
            locations: OrphanDetectorLocations(librarySubdirectories: [caches], receiptsDirectory: root.appendingPathComponent("receipts")),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: root.appendingPathComponent("missing.json"))
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }
}
