import Foundation

struct AppPreferences: Equatable, Sendable {
    static let defaultMoveToTrash = true
    static let defaultSkipRunningApps = true
    static let defaultShowDeveloperCaches = true
    static let defaultScanDSStores = true
    static let defaultShowNotifications = true
    static let defaultTempFileAgeHours = 168

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
            defaultValue: Self.defaultMoveToTrash,
            userDefaults: userDefaults
        )
        skipRunningApps = Self.boolValue(
            forKey: "skipRunningApps",
            defaultValue: Self.defaultSkipRunningApps,
            userDefaults: userDefaults
        )
        showDeveloperCaches = Self.boolValue(
            forKey: "showDeveloperCaches",
            defaultValue: Self.defaultShowDeveloperCaches,
            userDefaults: userDefaults
        )
        scanDSStores = Self.boolValue(
            forKey: "scanDSStores",
            defaultValue: Self.defaultScanDSStores,
            userDefaults: userDefaults
        )
        minTempFileAgeHours =
            userDefaults.object(forKey: "minTempFileAgeHours") as? Int ?? Self.defaultTempFileAgeHours
        safeListEntries = ExclusionList.loadUserEntries(
            from: safeListURL,
            fileManager: fileManager
        )
    }

    static func boolValue(
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
