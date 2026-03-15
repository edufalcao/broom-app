import Foundation
import Testing
@testable import Broom

@Suite("OrphanDetector")
struct OrphanDetectorTests {
    @Test func detectsOrphansAndAssignsHighConfidence() async throws {
        let root = try TestSupport.makeTempDirectory()
        let applicationSupport = root.appendingPathComponent("Application Support")
        let savedState = root.appendingPathComponent("Saved Application State")
        try FileManager.default.createDirectory(at: applicationSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: savedState, withIntermediateDirectories: true)

        try TestSupport.writeFile(at: applicationSupport.appendingPathComponent("com.example.oldapp/data.dat"))
        try TestSupport.writeFile(at: savedState.appendingPathComponent("com.example.oldapp.savedState/state.dat"))

        let inventory = MockAppInventory(bundleIdentifiers: ["com.example.installed"])
        let detector = OrphanDetector(
            appInventory: inventory,
            locations: OrphanDetectorLocations(librarySubdirectories: [applicationSupport, savedState]),
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
            locations: OrphanDetectorLocations(librarySubdirectories: [caches]),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: safeListURL)
            }
        )

        let orphans = await detector.detectOrphans()
        #expect(orphans.isEmpty)
    }
}
