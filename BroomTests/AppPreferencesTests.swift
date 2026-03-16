import Foundation
import Testing
@testable import Broom

@Suite("AppPreferences")
struct AppPreferencesTests {
    @Test func loadsDefaultsWhenNothingStored() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let safeListURL = try TestSupport.makeTempDirectory()
            .appendingPathComponent("safelist.json")

        let preferences = AppPreferences(
            userDefaults: defaults,
            safeListURL: safeListURL
        )

        #expect(preferences.moveToTrash == true)
        #expect(preferences.skipRunningApps == true)
        #expect(preferences.showDeveloperCaches == true)
        #expect(preferences.scanDSStores == true)
        #expect(preferences.minTempFileAgeHours == AppPreferences.defaultTempFileAgeHours)
        #expect(preferences.safeListEntries.isEmpty)
    }

    @Test func loadsStoredValuesAndSafeList() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "moveToTrash")
        defaults.set(false, forKey: "skipRunningApps")
        defaults.set(false, forKey: "showDeveloperCaches")
        defaults.set(false, forKey: "scanDSStores")
        defaults.set(48, forKey: "minTempFileAgeHours")

        let directory = try TestSupport.makeTempDirectory()
        let safeListURL = directory.appendingPathComponent("safelist.json")
        let safeListData = try JSONEncoder().encode([
            "/tmp/keep-me",
            "com.example.safe",
        ])
        try safeListData.write(to: safeListURL)

        let preferences = AppPreferences(
            userDefaults: defaults,
            safeListURL: safeListURL
        )

        #expect(preferences.moveToTrash == false)
        #expect(preferences.skipRunningApps == false)
        #expect(preferences.showDeveloperCaches == false)
        #expect(preferences.scanDSStores == false)
        #expect(preferences.minTempFileAgeHours == 48)
        #expect(preferences.safeListEntries.contains("/tmp/keep-me"))
        #expect(preferences.safeListEntries.contains("com.example.safe"))
    }
}
