import AppKit
import Foundation

struct AppInventoryLocations {
    let applicationDirectories: [URL]
    let librarySearchDirectories: [(String, URL)]
    let preferencesDirectory: URL
    let launchAgentDirectories: [(String, URL)]

    static let live = AppInventoryLocations(
        applicationDirectories: Constants.applicationDirectories,
        librarySearchDirectories: [
            ("Application Support", Constants.library.appendingPathComponent("Application Support")),
            ("Caches", Constants.userCaches),
            ("Containers", Constants.library.appendingPathComponent("Containers")),
            ("Group Containers", Constants.library.appendingPathComponent("Group Containers")),
            ("Saved Application State", Constants.library.appendingPathComponent("Saved Application State")),
            ("WebKit", Constants.library.appendingPathComponent("WebKit")),
            ("HTTPStorages", Constants.library.appendingPathComponent("HTTPStorages")),
            ("Logs", Constants.userLogs),
        ],
        preferencesDirectory: Constants.library.appendingPathComponent("Preferences"),
        launchAgentDirectories: [
            ("Launch Agents", Constants.userLaunchAgents),
            ("Launch Agents", Constants.systemLaunchAgents),
            ("Launch Daemons", Constants.systemLaunchDaemons),
        ]
    )
}

actor AppInventory: AppInventoryServing {
    private let fileManager = FileManager.default
    private let locations: AppInventoryLocations

    init(locations: AppInventoryLocations = .live) {
        self.locations = locations
    }

    // MARK: - Installed Apps

    func loadAllApps() async -> [InstalledApp] {
        var apps: [InstalledApp] = []

        for dir in locations.applicationDirectories {
            apps.append(contentsOf: enumerateApps(in: dir))
        }

        var enrichedApps: [InstalledApp] = []
        for var app in apps {
            app.associatedFiles = await findAssociatedFiles(
                for: app.bundleIdentifier,
                appName: app.name
            )
            app.associatedFilesLoaded = true
            enrichedApps.append(app)
        }

        return enrichedApps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func installedBundleIdentifiers() async -> Set<String> {
        var ids: Set<String> = []

        for dir in locations.applicationDirectories {
            let apps = enumerateApps(in: dir)
            ids.formUnion(apps.map { $0.bundleIdentifier.lowercased() })
        }

        return ids
    }

    func loadApp(at url: URL) async -> InstalledApp? {
        guard var app = parseApp(at: url) else { return nil }
        app.associatedFiles = await findAssociatedFiles(
            for: app.bundleIdentifier,
            appName: app.name
        )
        app.associatedFilesLoaded = true
        return app
    }

    func findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let lowerBundleID = bundleID.lowercased()
        let lowerName = appName.lowercased()
        let organizationTokens = Self.organizationTokens(for: lowerBundleID)

        for (label, dir) in locations.librarySearchDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in contents {
                let name = entry.lastPathComponent.lowercased()
                if Self.matches(
                    entryName: name,
                    bundleID: lowerBundleID,
                    appName: lowerName,
                    organizationTokens: organizationTokens
                ) {
                    let size = directorySize(at: entry)
                    if size > 0 {
                        items.append(CleanableItem(
                            path: entry,
                            name: "\(label)/\(entry.lastPathComponent)",
                            size: size
                        ))
                    }
                }
            }
        }

        // Preferences plists
        if let contents = try? fileManager.contentsOfDirectory(
            at: locations.preferencesDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for entry in contents where entry.pathExtension == "plist" {
                let name = entry.deletingPathExtension().lastPathComponent.lowercased()
                if Self.matches(
                    entryName: name,
                    bundleID: lowerBundleID,
                    appName: lowerName,
                    organizationTokens: organizationTokens
                ) {
                    let size = Int64((try? entry.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
                    if size > 0 {
                        items.append(CleanableItem(
                            path: entry,
                            name: "Preferences/\(entry.lastPathComponent)",
                            size: size
                        ))
                    }
                }
            }
        }

        for (label, dir) in locations.launchAgentDirectories {
            items.append(contentsOf: matchingLaunchItems(
                in: dir,
                label: label,
                bundleID: lowerBundleID,
                appName: lowerName,
                organizationTokens: organizationTokens
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    func appLastUsedDate(at url: URL) -> Date? {
        guard let mdItem = MDItemCreateWithURL(nil, url as CFURL) else { return nil }
        guard let lastUsed = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) else { return nil }
        return lastUsed as? Date
    }

    // MARK: - Helpers

    private func enumerateApps(in directory: URL) -> [InstalledApp] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var apps: [InstalledApp] = []

        for entry in contents {
            if entry.pathExtension == "app" {
                if let app = parseApp(at: entry) {
                    apps.append(app)
                }
            } else {
                // Check subdirectories (e.g. /Applications/Utilities/)
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue {
                    apps.append(contentsOf: enumerateApps(in: entry))
                }
            }
        }

        return apps
    }

    private func parseApp(at url: URL) -> InstalledApp? {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        guard let bundleID = plist["CFBundleIdentifier"] as? String else { return nil }

        let name = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent

        let version = (plist["CFBundleShortVersionString"] as? String) ?? ""

        let isSystemApp = url.path.hasPrefix("/System/Applications")
        let isAppleApp = bundleID.lowercased().hasPrefix("com.apple.")

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        let bundleSize = directorySize(at: url)
        let lastUsed = appLastUsedDate(at: url)

        return InstalledApp(
            name: name,
            bundleIdentifier: bundleID,
            version: version,
            bundlePath: url,
            bundleSize: bundleSize,
            icon: icon,
            isSystemApp: isSystemApp,
            isAppleApp: isAppleApp,
            associatedFilesLoaded: false,
            lastUsedDate: lastUsed
        )
    }

    private func directorySize(at url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }

        if !isDirectory.boolValue {
            return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }

        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]
            ) else { continue }
            if values.isRegularFile == true {
                totalSize += Int64(values.totalFileAllocatedSize ?? 0)
            }
        }
        return totalSize
    }

    private func matchingLaunchItems(
        in directory: URL,
        label: String,
        bundleID: String,
        appName: String,
        organizationTokens: Set<String>
    ) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { entry in
            let name = entry.lastPathComponent.lowercased()
            let matchesName = Self.matches(
                entryName: name,
                bundleID: bundleID,
                appName: appName,
                organizationTokens: organizationTokens
            )
            let matchesPlist = plistContainsMatch(
                at: entry,
                bundleID: bundleID,
                appName: appName,
                organizationTokens: organizationTokens
            )

            guard matchesName || matchesPlist else { return nil }

            let size = directorySize(at: entry)
            guard size > 0 else { return nil }

            return CleanableItem(
                path: entry,
                name: "\(label)/\(entry.lastPathComponent)",
                size: size
            )
        }
    }

    private func plistContainsMatch(
        at url: URL,
        bundleID: String,
        appName: String,
        organizationTokens: Set<String>
    ) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil)
        else {
            return false
        }

        return Self.stringValues(in: propertyList).contains { value in
            Self.matches(
                entryName: value.lowercased(),
                bundleID: bundleID,
                appName: appName,
                organizationTokens: organizationTokens
            )
        }
    }

    private static func matches(
        entryName: String,
        bundleID: String,
        appName: String,
        organizationTokens: Set<String>
    ) -> Bool {
        if entryName.contains(bundleID) || entryName.contains(appName) {
            return true
        }

        return organizationTokens.contains { token in
            token.count >= 3 && entryName.contains(token)
        }
    }

    private static func organizationTokens(for bundleID: String) -> Set<String> {
        let parts = bundleID.split(separator: ".").map(String.init)
        let middleParts = parts.dropFirst().dropLast()

        var tokens = Set(middleParts.map { $0.lowercased() })
        if parts.count >= 2 {
            tokens.insert(parts[1].lowercased())
        }
        return tokens.filter { $0.count >= 3 }
    }

    private static func stringValues(in propertyList: Any) -> [String] {
        switch propertyList {
        case let string as String:
            return [string]
        case let array as [Any]:
            return array.flatMap(stringValues(in:))
        case let dictionary as [String: Any]:
            return dictionary.values.flatMap(stringValues(in:))
        default:
            return []
        }
    }
}
