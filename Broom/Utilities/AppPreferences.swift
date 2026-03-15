import Foundation

struct AppPreferences: Equatable, Sendable {
    let moveToTrash: Bool
    let skipRunningApps: Bool
    let showDeveloperCaches: Bool
    let scanDSStores: Bool
    let minTempFileAgeHours: Int
    let safeListEntries: Set<String>

    init(
        userDefaults: UserDefaults = .standard,
        safeListURL: URL = Constants.safeListPath,
        fileManager: FileManager = .default
    ) {
        moveToTrash = Self.boolValue(
            forKey: "moveToTrash",
            defaultValue: true,
            userDefaults: userDefaults
        )
        skipRunningApps = Self.boolValue(
            forKey: "skipRunningApps",
            defaultValue: true,
            userDefaults: userDefaults
        )
        showDeveloperCaches = Self.boolValue(
            forKey: "showDeveloperCaches",
            defaultValue: true,
            userDefaults: userDefaults
        )
        scanDSStores = Self.boolValue(
            forKey: "scanDSStores",
            defaultValue: true,
            userDefaults: userDefaults
        )
        minTempFileAgeHours = userDefaults.object(forKey: "minTempFileAgeHours") as? Int ?? 24
        safeListEntries = ExclusionList.loadUserEntries(
            from: safeListURL,
            fileManager: fileManager
        )
    }

    private static func boolValue(
        forKey key: String,
        defaultValue: Bool,
        userDefaults: UserDefaults
    ) -> Bool {
        guard userDefaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return userDefaults.bool(forKey: key)
    }
}
