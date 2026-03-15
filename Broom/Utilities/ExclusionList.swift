import Foundation

enum ExclusionList {
    static func isExcluded(_ path: URL) -> Bool {
        let name = path.lastPathComponent

        // Own bundle
        if name == Constants.bundleIdentifier { return true }

        // System-critical caches
        if Constants.protectedCacheIdentifiers.contains(name) { return true }

        // Protected bundle ID prefixes
        for prefix in Constants.protectedBundleIDPrefixes {
            if name.hasPrefix(prefix) { return true }
        }

        return false
    }

    static func isProtectedBundleID(_ id: String) -> Bool {
        let lowered = id.lowercased()
        return Constants.protectedBundleIDPrefixes.contains { lowered.hasPrefix($0) }
    }
}
