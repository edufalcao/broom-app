import Foundation

struct UninstallArtifactPlanner {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func planArtifacts(for app: InstalledApp) -> [CleanableItem] {
        let bundleID = app.bundleIdentifier.lowercased()
        let nameVariants = Self.nameVariants(for: app.name)
        var seen = Set<String>()
        var items: [CleanableItem] = []

        func append(_ item: CleanableItem) {
            let key = item.path.standardizedFileURL.path
            if seen.insert(key).inserted {
                items.append(item)
            }
        }

        for item in userDataArtifacts(bundleID: bundleID, nameVariants: nameVariants) {
            append(item)
        }
        for item in preferencesArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in cachesArtifacts(bundleID: bundleID, nameVariants: nameVariants) {
            append(item)
        }
        for item in groupContainerArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in webDataArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in savedStateArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in logsArtifacts(bundleID: bundleID, nameVariants: nameVariants) {
            append(item)
        }
        for item in launchItemsArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in helpersArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in receiptsArtifacts(bundleID: bundleID) {
            append(item)
        }
        for item in appScriptsArtifacts(bundleID: bundleID) {
            append(item)
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Name Variant Generation

    static let channelSuffixes: Set<String> = [
        "beta", "canary", "dev", "nightly", "alpha", "rc", "preview"
    ]

    static func nameVariants(for appName: String) -> [String] {
        let trimmed = trimVersionAndChannel(from: appName)
        var variants: [String] = []

        variants.append(trimmed)
        variants.append(trimmed.replacingOccurrences(of: " ", with: ""))
        variants.append(trimmed.replacingOccurrences(of: " ", with: "-"))
        variants.append(trimmed.replacingOccurrences(of: " ", with: "_"))

        let lower = trimmed.lowercased()
        variants.append(lower)
        variants.append(lower.replacingOccurrences(of: " ", with: ""))
        variants.append(lower.replacingOccurrences(of: " ", with: "-"))
        variants.append(lower.replacingOccurrences(of: " ", with: "_"))

        return Array(NSOrderedSet(array: variants)) as! [String]
    }

    static func trimVersionAndChannel(from name: String) -> String {
        var words = name.split(separator: " ").map(String.init)
        while let last = words.last {
            let lower = last.lowercased()
            let isVersion = lower.allSatisfy { $0.isNumber || $0 == "." }
            if channelSuffixes.contains(lower) || isVersion {
                words.removeLast()
            } else {
                break
            }
        }
        return words.isEmpty ? name : words.joined(separator: " ")
    }

    // MARK: - Artifact Providers

    private func userDataArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        let appSupport = Constants.library.appendingPathComponent("Application Support")
        let containers = Constants.library.appendingPathComponent("Containers")

        var items: [CleanableItem] = []

        if let item = artifactIfExists(appSupport.appendingPathComponent(bundleID), source: .userData, label: "Application Support") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(appSupport.appendingPathComponent(variant), source: .userData, label: "Application Support") {
                items.append(item)
            }
        }

        if let item = artifactIfExists(containers.appendingPathComponent(bundleID), source: .userData, label: "Containers") {
            items.append(item)
        }

        return items
    }

    private func preferencesArtifacts(bundleID: String) -> [CleanableItem] {
        let prefs = Constants.library.appendingPathComponent("Preferences")
        let byHost = prefs.appendingPathComponent("ByHost")
        var items: [CleanableItem] = []

        let plistPath = prefs.appendingPathComponent("\(bundleID).plist")
        if let item = artifactIfExists(plistPath, source: .preferences, label: "Preferences") {
            items.append(item)
        }

        items.append(contentsOf: globMatchingEntries(
            in: byHost,
            pattern: bundleID,
            source: .preferences,
            label: "Preferences/ByHost"
        ))

        return items
    }

    private func cachesArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        var items: [CleanableItem] = []

        if let item = artifactIfExists(Constants.userCaches.appendingPathComponent(bundleID), source: .caches, label: "Caches") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(Constants.userCaches.appendingPathComponent(variant), source: .caches, label: "Caches") {
                items.append(item)
            }
        }

        return items
    }

    private func groupContainerArtifacts(bundleID: String) -> [CleanableItem] {
        let groupContainers = Constants.library.appendingPathComponent("Group Containers")
        return globMatchingEntries(
            in: groupContainers,
            pattern: bundleID,
            source: .groupContainers,
            label: "Group Containers"
        )
    }

    private func webDataArtifacts(bundleID: String) -> [CleanableItem] {
        let webkit = Constants.library.appendingPathComponent("WebKit")
        let cookies = Constants.library.appendingPathComponent("Cookies")
        let httpStorages = Constants.library.appendingPathComponent("HTTPStorages")
        var items: [CleanableItem] = []

        if let item = artifactIfExists(webkit.appendingPathComponent(bundleID), source: .webData, label: "WebKit") {
            items.append(item)
        }
        if let item = artifactIfExists(cookies.appendingPathComponent("\(bundleID).binarycookies"), source: .webData, label: "Cookies") {
            items.append(item)
        }
        if let item = artifactIfExists(httpStorages.appendingPathComponent(bundleID), source: .webData, label: "HTTPStorages") {
            items.append(item)
        }

        return items
    }

    private func savedStateArtifacts(bundleID: String) -> [CleanableItem] {
        let savedState = Constants.library.appendingPathComponent("Saved Application State")
        let path = savedState.appendingPathComponent("\(bundleID).savedState")
        if let item = artifactIfExists(path, source: .savedState, label: "Saved Application State") {
            return [item]
        }
        return []
    }

    private func logsArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        var items: [CleanableItem] = []

        if let item = artifactIfExists(Constants.userLogs.appendingPathComponent(bundleID), source: .logs, label: "Logs") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(Constants.userLogs.appendingPathComponent(variant), source: .logs, label: "Logs") {
                items.append(item)
            }
        }

        let diagnosticReports = Constants.library.appendingPathComponent("Logs/DiagnosticReports")
        for variant in nameVariants {
            items.append(contentsOf: globMatchingEntries(
                in: diagnosticReports,
                pattern: variant,
                source: .logs,
                label: "DiagnosticReports"
            ))
        }

        return items
    }

    private func launchItemsArtifacts(bundleID: String) -> [CleanableItem] {
        var items: [CleanableItem] = []

        items.append(contentsOf: globMatchingEntries(
            in: Constants.userLaunchAgents,
            pattern: bundleID,
            source: .launchItems,
            label: "Launch Agents"
        ))
        items.append(contentsOf: globMatchingEntries(
            in: Constants.systemLaunchAgents,
            pattern: bundleID,
            source: .launchItems,
            label: "Launch Agents"
        ))
        items.append(contentsOf: globMatchingEntries(
            in: Constants.systemLaunchDaemons,
            pattern: bundleID,
            source: .launchItems,
            label: "Launch Daemons"
        ))

        return items
    }

    private func helpersArtifacts(bundleID: String) -> [CleanableItem] {
        let helpers = URL(fileURLWithPath: "/Library/PrivilegedHelperTools")
        return globMatchingEntries(
            in: helpers,
            pattern: bundleID,
            source: .helpers,
            label: "Helpers"
        )
    }

    private func receiptsArtifacts(bundleID: String) -> [CleanableItem] {
        let receipts = URL(fileURLWithPath: "/var/db/receipts")
        return globMatchingEntries(
            in: receipts,
            pattern: bundleID,
            source: .receipts,
            label: "Receipts"
        )
    }

    private func appScriptsArtifacts(bundleID: String) -> [CleanableItem] {
        let scripts = Constants.library.appendingPathComponent("Application Scripts")
        let path = scripts.appendingPathComponent(bundleID)
        if let item = artifactIfExists(path, source: .appScripts, label: "Application Scripts") {
            return [item]
        }
        return []
    }

    // MARK: - Helpers

    private func artifactIfExists(_ url: URL, source: UninstallArtifactSource, label: String) -> CleanableItem? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let size = itemSize(at: url)
        return CleanableItem(
            path: url,
            name: "\(label)/\(url.lastPathComponent)",
            size: size,
            source: source
        )
    }

    private func globMatchingEntries(
        in directory: URL,
        pattern: String,
        source: UninstallArtifactSource,
        label: String
    ) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let lowerPattern = pattern.lowercased()
        return contents.compactMap { entry in
            let name = entry.lastPathComponent.lowercased()
            guard name.contains(lowerPattern) else { return nil }
            let size = itemSize(at: entry)
            return CleanableItem(
                path: entry,
                name: "\(label)/\(entry.lastPathComponent)",
                size: size,
                source: source
            )
        }
    }

    private func itemSize(at url: URL) -> Int64 {
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
}
