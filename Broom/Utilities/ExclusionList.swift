import Foundation

enum ExclusionList {
    static func isExcluded(_ path: URL, userEntries: Set<String> = loadUserEntries()) -> Bool {
        let name = path.lastPathComponent

        // Own bundle
        if name == Constants.bundleIdentifier { return true }

        // System-critical caches
        if Constants.protectedCacheIdentifiers.contains(name) { return true }

        // Protected bundle ID prefixes
        for prefix in Constants.protectedBundleIDPrefixes {
            if name.hasPrefix(prefix) { return true }
        }

        if matchesUserEntry(path, entries: userEntries) { return true }

        return false
    }

    static func isProtectedBundleID(_ id: String) -> Bool {
        let lowered = id.lowercased()
        return Constants.protectedBundleIDPrefixes.contains { lowered.hasPrefix($0) }
    }

    /// Checks if a path should be excluded based on built-in rules only (no user entries).
    /// Useful for quick suppression checks that don't need the user safe-list.
    static func isExcludedPath(_ path: URL) -> Bool {
        isExcluded(path, userEntries: [])
    }

    static func loadUserEntries(
        from url: URL = Constants.safeListPath,
        fileManager: FileManager = .default
    ) -> Set<String> {
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(
            list
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    static func matchesUserEntry(_ path: URL, entries: Set<String>) -> Bool {
        guard !entries.isEmpty else { return false }

        let normalizedPath = path.standardizedFileURL.path.lowercased()
        let loweredName = path.lastPathComponent.lowercased()

        for rawEntry in entries {
            let entry = rawEntry.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !entry.isEmpty else { continue }

            let expandedEntry = NSString(string: entry).expandingTildeInPath
            let loweredEntry = expandedEntry.lowercased()

            if expandedEntry.contains("/") {
                let normalizedEntry = URL(fileURLWithPath: expandedEntry).standardizedFileURL.path.lowercased()
                if normalizedPath == normalizedEntry || normalizedPath.hasPrefix(normalizedEntry + "/") {
                    return true
                }
                continue
            }

            if loweredName == loweredEntry || loweredName.hasPrefix(loweredEntry) {
                return true
            }

            if normalizedPath.contains("/\(loweredEntry)") || normalizedPath.contains(loweredEntry) {
                return true
            }
        }

        return false
    }
}
