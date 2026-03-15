import Foundation

actor OrphanDetector {
    private let fileManager = FileManager.default
    private let appInventory: AppInventory

    init(appInventory: AppInventory) {
        self.appInventory = appInventory
    }

    func detectOrphans() async -> [OrphanedApp] {
        let installedIDs = await appInventory.installedBundleIdentifiers()
        var orphanMap: [String: [CleanableItem]] = [:]

        for dir in Constants.librarySubdirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in contents {
                let name = entry.lastPathComponent

                // Skip protected entries
                if ExclusionList.isExcluded(entry) { continue }

                // Skip if matches an installed app
                if BundleIDMatcher.matches(directoryName: name, againstInstalled: installedIDs) { continue }

                // Skip tiny entries
                let size = directorySize(at: entry)
                guard size > 1024 else { continue } // > 1KB

                let appName = BundleIDMatcher.inferAppName(from: name)
                let item = CleanableItem(
                    path: entry,
                    name: "\(dir.lastPathComponent)/\(name)",
                    size: size,
                    isSelected: false // Orphans default to unselected
                )

                orphanMap[appName, default: []].append(item)
            }
        }

        var orphans: [OrphanedApp] = []
        for (appName, locations) in orphanMap {
            let confidence = assignConfidence(locations: locations)
            orphans.append(OrphanedApp(
                appName: appName,
                bundleIdentifier: extractBundleID(from: locations),
                confidence: confidence,
                locations: locations
            ))
        }

        return orphans.sorted { $0.totalSize > $1.totalSize }
    }

    private func assignConfidence(locations: [CleanableItem]) -> OrphanConfidence {
        let hasSavedState = locations.contains {
            $0.path.path.contains("Saved Application State")
        }
        let hasBundleIDPattern = locations.contains {
            $0.path.lastPathComponent.split(separator: ".").count >= 3
        }

        if hasSavedState && hasBundleIDPattern { return .high }
        if hasBundleIDPattern { return .medium }
        return .low
    }

    private func extractBundleID(from locations: [CleanableItem]) -> String? {
        for loc in locations {
            let name = loc.path.lastPathComponent
            if name.split(separator: ".").count >= 3 {
                return name
            }
        }
        return nil
    }

    private func directorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        var isDir: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }

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
