import Foundation

enum BundleIDMatcher {
    static func strictMatch(candidate: String, against installed: Set<String>) -> Bool {
        guard !candidate.isEmpty else { return false }
        let normalized = candidate.lowercased()

        if installed.contains(normalized) { return true }

        for id in installed {
            if normalized.hasPrefix(id + ".") || id.hasPrefix(normalized + ".") { return true }
            // Group Containers use {TeamID}.{BundleID} format
            if normalized.hasSuffix("." + id) { return true }
        }

        return false
    }

    static func broadMatch(candidate: String, against installed: Set<String>) -> Bool {
        guard !candidate.isEmpty else { return false }
        let normalized = candidate.lowercased()

        if installed.contains(normalized) { return true }

        for id in installed {
            if normalized.hasPrefix(id) || id.hasPrefix(normalized) { return true }
        }

        let strippedName = normalized.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
        for id in installed {
            let strippedID = id.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "-", with: "")
            if strippedName == strippedID { return true }
        }

        for id in installed {
            let parts = id.split(separator: ".")
            if let lastPart = parts.last {
                let shortName = String(lastPart).lowercased()
                if shortName.count >= 3 && normalized.contains(shortName) { return true }
                if shortName.count >= 3 && shortName.contains(normalized) { return true }
            }
        }

        return false
    }

    static func matches(directoryName: String, againstInstalled installed: Set<String>) -> Bool {
        broadMatch(candidate: directoryName, against: installed)
    }

    static func inferAppName(from directoryName: String) -> String {
        let parts = directoryName.split(separator: ".")
        if parts.count >= 3 {
            if let lastPart = parts.last,
               lastPart.lowercased() == "savedstate",
               parts.count >= 4
            {
                return String(parts[parts.count - 2])
            }
            return String(parts.last!)
        }
        return directoryName
    }
}
