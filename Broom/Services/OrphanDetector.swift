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
        let installedIDs = await appInventory.installedBundleIdentifiers()
        let preferences = preferencesProvider()
        let receiptBundleIDs = loadReceiptBundleIDs()
        let spotlightBundleIDs = await querySpotlightBundleIDs()

        // Only installed apps suppress orphan candidates.
        // Receipt and Spotlight signals are reserved for confidence scoring.
        let allKnownIDs = installedIDs

        var orphanMap: [String: [CleanableItem]] = [:]

        for dir in locations.librarySubdirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in contents {
                let name = entry.lastPathComponent

                // Skip protected entries
                if ExclusionList.isExcluded(entry, userEntries: preferences.safeListEntries) { continue }

                // Skip if matches an installed app
                if BundleIDMatcher.matches(directoryName: name, againstInstalled: allKnownIDs) { continue }

                // Skip tiny entries
                let size = directorySize(at: entry)
                guard size > 1024 else { continue }

                let appName = BundleIDMatcher.inferAppName(from: name)
                let item = CleanableItem(
                    path: entry,
                    name: "\(dir.lastPathComponent)/\(name)",
                    size: size,
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

        // Check if Spotlight has seen this bundle ID before
        // (means macOS previously indexed this app)
        let hasSpotlightRecord = locations.contains { loc in
            let name = loc.path.lastPathComponent.lowercased()
            return spotlightBundleIDs.contains(name)
        }

        // High: multiple strong signals
        if (hasSavedState && hasBundleIDPattern) || hasReceipt {
            return .high
        }

        // Medium: at least one moderate signal
        if hasBundleIDPattern || hasSpotlightRecord {
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
