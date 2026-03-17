@preconcurrency import Foundation

struct OrphanDetectorLocations {
    let librarySubdirectories: [URL]
    let receiptsDirectory: URL

    static let live = OrphanDetectorLocations(
        librarySubdirectories: Constants.librarySubdirectories,
        receiptsDirectory: URL(fileURLWithPath: "/var/db/receipts")
    )
}

actor OrphanDetector: OrphanDetecting {
    private let fileManager: FileManager
    private let appInventory: AppInventoryServing
    private let locations: OrphanDetectorLocations
    private let preferencesProvider: @Sendable () -> AppPreferences

    /// Minimum size threshold: candidates smaller than this are not worth showing.
    private static let minimumSizeThreshold: Int64 = 4096

    init(
        appInventory: AppInventoryServing,
        fileManager: FileManager = .default,
        locations: OrphanDetectorLocations = .live,
        preferencesProvider: @escaping @Sendable () -> AppPreferences = { AppPreferences() }
    ) {
        self.appInventory = appInventory
        self.fileManager = fileManager
        self.locations = locations
        self.preferencesProvider = preferencesProvider
    }

    func detectOrphans() async -> [OrphanedApp] {
        let snapshot = await appInventory.buildSnapshot()
        let preferences = preferencesProvider()
        let receiptBundleIDs = loadReceiptBundleIDs()
        let spotlightBundleIDs = await querySpotlightBundleIDs()

        let staleAgeThreshold = Calendar.current.date(
            byAdding: .day,
            value: -preferences.orphanStaleAgeDays,
            to: Date()
        ) ?? Date()

        var orphanMap: [String: [CleanableItem]] = [:]

        for dir in locations.librarySubdirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in contents {
                let name = entry.lastPathComponent

                // --- Suppression gate: only candidates that pass ALL checks survive ---

                // 1. Pattern gate: only consider entries matching strict orphan patterns
                guard matchesOrphanPattern(name: name, parentDir: dir) else { continue }

                // 2. Protected path check (ExclusionList built-in rules + user safe-list)
                if ExclusionList.isExcluded(entry, userEntries: preferences.safeListEntries) { continue }

                // 3. Protected data-family check (ProtectedDataPolicy)
                if ProtectedDataPolicy.isProtected(path: entry) { continue }

                // 4. Installed app snapshot match (strict match only)
                if BundleIDMatcher.strictMatch(candidate: name, against: snapshot.installedBundleIDs) { continue }

                // 5. Running app match
                if BundleIDMatcher.strictMatch(candidate: name, against: snapshot.runningBundleIDs) { continue }

                // 6. Launch item match
                if matchesLaunchItem(name: name, launchItemLabels: snapshot.launchItemLabels) { continue }

                // 7. Spotlight/LaunchServices existence — suppress if Spotlight shows it as installed
                if spotlightBundleIDs.contains(name.lowercased()) { continue }

                // 8. Size threshold — suppress tiny entries (< 4KB)
                let size = directorySize(at: entry)
                guard size >= Self.minimumSizeThreshold else { continue }

                // 9. Recent modification threshold — suppress recently modified candidates
                let modDate = modificationDate(at: entry)
                if modDate > staleAgeThreshold { continue }

                let appName = BundleIDMatcher.inferAppName(from: name)
                let item = CleanableItem(
                    path: entry,
                    name: "\(dir.lastPathComponent)/\(name)",
                    size: size,
                    modifiedDate: modDate,
                    isSelected: false
                )

                orphanMap[appName, default: []].append(item)
            }
        }

        var orphans: [OrphanedApp] = []
        for (appName, locations) in orphanMap {
            let confidence = assignConfidence(
                locations: locations,
                receiptBundleIDs: receiptBundleIDs,
                spotlightBundleIDs: spotlightBundleIDs
            )
            orphans.append(OrphanedApp(
                appName: appName,
                bundleIdentifier: extractBundleID(from: locations),
                confidence: confidence,
                locations: locations
            ))
        }

        return orphans.sorted { $0.totalSize > $1.totalSize }
    }

    // MARK: - Orphan Pattern Matching

    /// Only entries matching one of these strict patterns are considered orphan candidates.
    /// This prevents low-signal name-only heuristics from generating false positives.
    private func matchesOrphanPattern(name: String, parentDir: URL) -> Bool {
        // Reverse-DNS bundle-style directories (e.g., com.company.AppName)
        let parts = name.split(separator: ".")
        if parts.count >= 3 {
            return true
        }

        // .savedState directories
        if name.hasSuffix(".savedState") {
            return true
        }

        // .binarycookies files
        if name.hasSuffix(".binarycookies") {
            return true
        }

        // .plist files in Preferences directory
        let parentName = parentDir.lastPathComponent
        if parentName == "Preferences" && name.hasSuffix(".plist") && parts.count >= 2 {
            return true
        }

        return false
    }

    // MARK: - Launch Item Matching

    private func matchesLaunchItem(name: String, launchItemLabels: Set<String>) -> Bool {
        guard !launchItemLabels.isEmpty else { return false }
        let lowered = name.lowercased()
        return launchItemLabels.contains { lowered.hasPrefix($0.lowercased()) }
    }

    // MARK: - Confidence Scoring

    private func assignConfidence(
        locations: [CleanableItem],
        receiptBundleIDs: Set<String>,
        spotlightBundleIDs: Set<String>
    ) -> OrphanConfidence {
        let hasSavedState = locations.contains {
            $0.path.path.contains("Saved Application State")
        }
        let hasBundleIDPattern = locations.contains {
            $0.path.lastPathComponent.split(separator: ".").count >= 3
        }

        // Check if any location's bundle ID appears in the receipts database
        // (macOS logs .pkg installs here — strong signal the app existed)
        let hasReceipt = locations.contains { loc in
            let name = loc.path.lastPathComponent.lowercased()
            return receiptBundleIDs.contains(name)
        }

        // High: multiple strong signals
        if (hasSavedState && hasBundleIDPattern) || hasReceipt {
            return .high
        }

        // Medium: at least one moderate signal
        if hasBundleIDPattern {
            return .medium
        }

        return .low
    }

    // MARK: - Receipt Database (/var/db/receipts/)

    /// Reads installer package receipts to find bundle IDs of apps that were
    /// installed via .pkg. Each receipt plist contains a PackageIdentifier.
    private func loadReceiptBundleIDs() -> Set<String> {
        let receiptsDir = locations.receiptsDirectory
        guard let files = try? fileManager.contentsOfDirectory(
            at: receiptsDir,
            includingPropertiesForKeys: nil,
            options: []
        ) else { return [] }

        var ids = Set<String>()
        for file in files where file.pathExtension == "plist" {
            guard let data = try? Data(contentsOf: file),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let packageID = plist["PackageIdentifier"] as? String
            else { continue }
            ids.insert(packageID.lowercased())
        }
        return ids
    }

    // MARK: - Spotlight Metadata Query

    /// Queries Spotlight for all known bundle identifiers on the system.
    /// This catches apps that were registered with Launch Services but may
    /// have been deleted — Spotlight remembers them.
    private func querySpotlightBundleIDs() async -> Set<String> {
        await withCheckedContinuation { continuation in
            let query = NSMetadataQuery()
            query.predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")
            query.searchScopes = [NSMetadataQueryLocalComputerScope]
            query.valueListAttributes = [kMDItemCFBundleIdentifier as String]

            var didResume = false
            var observer: NSObjectProtocol?

            func finish(_ ids: Set<String>) {
                guard !didResume else { return }
                didResume = true
                if let observer { NotificationCenter.default.removeObserver(observer) }
                continuation.resume(returning: ids)
            }

            observer = NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: query,
                queue: .main
            ) { _ in
                query.stop()
                var ids = Set<String>()
                for i in 0..<query.resultCount {
                    if let result = query.result(at: i) as? NSMetadataItem,
                       let bundleID = result.value(forAttribute: kMDItemCFBundleIdentifier as String) as? String {
                        ids.insert(bundleID.lowercased())
                    }
                }
                finish(ids)
            }

            DispatchQueue.main.async {
                query.start()
            }

            // Timeout after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if query.isGathering {
                    query.stop()
                    finish([])
                }
            }
        }
    }

    // MARK: - Helpers

    private func extractBundleID(from locations: [CleanableItem]) -> String? {
        for loc in locations {
            let name = loc.path.lastPathComponent
            if name.split(separator: ".").count >= 3 {
                return name
            }
        }
        return nil
    }

    private func modificationDate(at url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? Date.distantPast
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
