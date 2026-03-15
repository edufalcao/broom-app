import AppKit
import Foundation

actor AppInventory {
    private let fileManager = FileManager.default

    // MARK: - Installed Apps

    func loadAllApps() async -> [InstalledApp] {
        var apps: [InstalledApp] = []

        for dir in Constants.applicationDirectories {
            apps.append(contentsOf: enumerateApps(in: dir))
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func installedBundleIdentifiers() async -> Set<String> {
        let apps = await loadAllApps()
        return Set(apps.map { $0.bundleIdentifier.lowercased() })
    }

    func findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let lowerBundleID = bundleID.lowercased()
        let lowerName = appName.lowercased()

        let searchDirs: [(String, URL)] = [
            ("Application Support", Constants.library.appendingPathComponent("Application Support")),
            ("Caches", Constants.userCaches),
            ("Containers", Constants.library.appendingPathComponent("Containers")),
            ("Group Containers", Constants.library.appendingPathComponent("Group Containers")),
            ("Saved Application State", Constants.library.appendingPathComponent("Saved Application State")),
            ("WebKit", Constants.library.appendingPathComponent("WebKit")),
            ("HTTPStorages", Constants.library.appendingPathComponent("HTTPStorages")),
            ("Logs", Constants.userLogs),
        ]

        for (label, dir) in searchDirs {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in contents {
                let name = entry.lastPathComponent.lowercased()
                if name.contains(lowerBundleID) || name.contains(lowerName) {
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
        let prefsDir = Constants.library.appendingPathComponent("Preferences")
        if let contents = try? fileManager.contentsOfDirectory(
            at: prefsDir, includingPropertiesForKeys: [.fileSizeKey], options: []
        ) {
            for entry in contents where entry.pathExtension == "plist" {
                let name = entry.deletingPathExtension().lastPathComponent.lowercased()
                if name.contains(lowerBundleID) || name.contains(lowerName) {
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

        return items
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
            lastUsedDate: lastUsed
        )
    }

    private func directorySize(at url: URL) -> Int64 {
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
}
