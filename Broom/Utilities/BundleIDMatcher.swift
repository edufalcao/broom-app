import Foundation

enum BundleIDMatcher {
    static func matches(directoryName: String, againstInstalled installed: Set<String>) -> Bool {
        let normalized = directoryName.lowercased()

        // Direct match
        if installed.contains(normalized) { return true }

        // Reverse-domain prefix match
        for id in installed {
            if normalized.hasPrefix(id) || id.hasPrefix(normalized) { return true }
        }

        // Normalized match (remove dots, hyphens)
        let strippedName = normalized.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
        for id in installed {
            let strippedID = id.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "-", with: "")
            if strippedName == strippedID { return true }
        }

        // Substring containment: check if any installed app's short name is in the directory
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

    static func inferAppName(from directoryName: String) -> String {
        // Try to extract a human-readable name from a bundle ID or directory name
        let parts = directoryName.split(separator: ".")
        if parts.count >= 3 {
            if let lastPart = parts.last,
               lastPart.lowercased() == "savedstate",
               parts.count >= 4
            {
                return String(parts[parts.count - 2])
            }
            // Looks like a bundle ID: com.company.AppName -> AppName
            return String(parts.last!)
        }
        return directoryName
    }
}
