import Foundation
import os

struct FileScannerLocations {
    let home: URL
    let userCaches: URL
    let chromeCacheBase: URL
    let firefoxCache: URL
    let safariCache: URL
    let arcCache: URL
    let braveCacheBase: URL
    let edgeCacheBase: URL
    let userLogs: URL
    let systemLogs: URL
    let diagnosticReports: URL
    let userTmpDir: URL
    let systemTmp: URL
    let xcodeDerivedData: URL
    let xcodeArchives: URL
    let spmCache: URL
    let cocoapodsCache: URL
    let homebrewCache: URL
    let npmCache: URL
    let yarnCache: URL
    let pipCache: URL
    let mailAttachments: URL

    static let live = FileScannerLocations(
        home: Constants.home,
        userCaches: Constants.userCaches,
        chromeCacheBase: Constants.userCaches.appendingPathComponent("Google/Chrome"),
        firefoxCache: Constants.firefoxCache,
        safariCache: Constants.safariCache,
        arcCache: Constants.arcCache,
        braveCacheBase: Constants.userCaches.appendingPathComponent("BraveSoftware/Brave-Browser"),
        edgeCacheBase: Constants.userCaches.appendingPathComponent("com.microsoft.edgemac"),
        userLogs: Constants.userLogs,
        systemLogs: Constants.systemLogs,
        diagnosticReports: Constants.diagnosticReports,
        userTmpDir: Constants.userTmpDir,
        systemTmp: Constants.systemTmp,
        xcodeDerivedData: Constants.xcodeDerivedData,
        xcodeArchives: Constants.xcodeArchives,
        spmCache: Constants.spmCache,
        cocoapodsCache: Constants.cocoapodsCache,
        homebrewCache: Constants.homebrewCache,
        npmCache: Constants.npmCache,
        yarnCache: Constants.yarnCache,
        pipCache: Constants.pipCache,
        mailAttachments: Constants.mailAttachments
    )
}

actor FileScanner: ScanServing {
    private let fileManager = FileManager.default
    private let locations: FileScannerLocations
    private let preferencesProvider: @Sendable () -> AppPreferences

    init(
        locations: FileScannerLocations = .live,
        preferencesProvider: @escaping @Sendable () -> AppPreferences = { AppPreferences() }
    ) {
        self.locations = locations
        self.preferencesProvider = preferencesProvider
    }

    // MARK: - Public API

    nonisolated func scanAll() -> AsyncStream<ScanProgress> {
        AsyncStream { continuation in
            Task {
                let startTime = Date()
                var categories: [CleanCategory] = []
                let preferences = preferencesProvider()
                let phases = scanPhases(for: preferences)
                let totalSteps = Double(max(phases.count, 1))

                func report(_ name: String, index: Int) {
                    continuation.yield(.scanning(
                        category: name,
                        progress: Double(index) / totalSteps,
                        foundSoFar: categories.reduce(0) { $0 + $1.totalSize }
                    ))
                }

                for (index, phase) in phases.enumerated() {
                    report(phase.displayName, index: index)
                    if let category = await runPhase(phase, preferences: preferences) {
                        categories.append(category)
                    }
                }

                let duration = Date().timeIntervalSince(startTime)
                let result = ScanResult(
                    categories: categories,
                    orphanedApps: [],
                    scanDuration: duration,
                    scanDate: Date()
                )
                continuation.yield(.complete(result))
                continuation.finish()
            }
        }
    }

    // MARK: - Category Scanners

    private nonisolated func scanPhases(for preferences: AppPreferences) -> [ScanPhase] {
        var phases: [ScanPhase] = [
            .systemCaches,
            .browserCaches,
            .logs,
            .temporaryFiles,
        ]

        if preferences.showDeveloperCaches {
            phases.append(.xcodeData)
            phases.append(.developerCaches)
        }

        if preferences.scanDSStores {
            phases.append(.dsStoreFiles)
        }

        phases.append(.mailAttachments)

        return phases
    }

    private func runPhase(
        _ phase: ScanPhase,
        preferences: AppPreferences
    ) async -> CleanCategory? {
        switch phase {
        case .systemCaches:
            return await scanSystemCaches(userEntries: preferences.safeListEntries)
        case .browserCaches:
            return await scanBrowserCaches(userEntries: preferences.safeListEntries)
        case .logs:
            return await scanLogs(userEntries: preferences.safeListEntries)
        case .temporaryFiles:
            return await scanTempFiles(preferences: preferences)
        case .xcodeData:
            return await scanXcode(userEntries: preferences.safeListEntries)
        case .developerCaches:
            return await scanDeveloperCaches(userEntries: preferences.safeListEntries)
        case .dsStoreFiles:
            return await scanDSStores(userEntries: preferences.safeListEntries)
        case .mailAttachments:
            return await scanMailAttachments(userEntries: preferences.safeListEntries)
        }
    }

    func scanSystemCaches(userEntries: Set<String>) async -> CleanCategory {
        let items = enumerateDirectories(
            at: locations.userCaches,
            excluding: Constants.protectedCacheIdentifiers,
            userEntries: userEntries
        )
        return CleanCategory(
            name: "System Caches",
            icon: "internaldrive",
            description: "Per-app cache directories that are safe to delete",
            items: items
        )
    }

    func scanBrowserCaches(userEntries: Set<String>) async -> CleanCategory {
        var items: [CleanableItem] = []

        let browserPaths: [(String, [URL])] = [
            ("Chrome", chromiumCachePaths(base: locations.chromeCacheBase)),
            ("Firefox", [locations.firefoxCache]),
            ("Safari", [locations.safariCache]),
            ("Arc", [locations.arcCache]),
            ("Brave", chromiumCachePaths(base: locations.braveCacheBase)),
            ("Edge", chromiumCachePaths(base: locations.edgeCacheBase, fallbackToBase: true)),
        ]

        for (name, paths) in browserPaths {
            for path in paths {
                if let item = makeCleanableItem(
                    at: path,
                    displayName: name,
                    userEntries: userEntries
                ) {
                    items.append(item)
                }
            }
        }

        return CleanCategory(
            name: "Browser Caches",
            icon: "globe",
            description: "Cached web content from browsers",
            items: items
        )
    }

    func scanLogs(userEntries: Set<String>) async -> CleanCategory {
        var items: [CleanableItem] = []

        for path in [locations.userLogs, locations.systemLogs] {
            if let item = makeCleanableItem(at: path, userEntries: userEntries) {
                items.append(item)
            }
        }

        if let item = makeCleanableItem(
            at: locations.diagnosticReports,
            displayName: "Crash Reports",
            userEntries: userEntries
        ) {
            items.append(item)
        }

        return CleanCategory(
            name: "System Logs",
            icon: "doc.text",
            description: "Application and system log files",
            items: items
        )
    }

    func scanTempFiles(preferences: AppPreferences) async -> CleanCategory {
        var items: [CleanableItem] = []
        let cutoff = Date().addingTimeInterval(-Double(preferences.minTempFileAgeHours) * 3600)

        for dir in [locations.userTmpDir, locations.systemTmp] {
            let oldFiles = enumerateFiles(
                at: dir,
                olderThan: cutoff,
                userEntries: preferences.safeListEntries
            )
            items.append(contentsOf: oldFiles)
        }

        return CleanCategory(
            name: "Temporary Files",
            icon: "clock.arrow.circlepath",
            description: "Temporary files older than \(preferences.minTempFileAgeHours) hours",
            items: items
        )
    }

    func scanXcode(userEntries: Set<String>) async -> CleanCategory? {
        var items: [CleanableItem] = []

        if let item = makeCleanableItem(
            at: locations.xcodeDerivedData,
            displayName: "Derived Data",
            userEntries: userEntries
        ) {
            items.append(item)
        }
        if let item = makeCleanableItem(
            at: locations.xcodeArchives,
            displayName: "Archives",
            userEntries: userEntries
        ) {
            items.append(item)
        }

        guard !items.isEmpty else { return nil }

        return CleanCategory(
            name: "Xcode Data",
            icon: "hammer",
            description: "Xcode build data and old archives",
            items: items
        )
    }

    func scanDeveloperCaches(userEntries: Set<String>) async -> CleanCategory {
        let caches: [(String, URL)] = [
            ("Swift Package Manager", locations.spmCache),
            ("CocoaPods", locations.cocoapodsCache),
            ("Homebrew", locations.homebrewCache),
            ("npm", locations.npmCache),
            ("Yarn", locations.yarnCache),
            ("pip", locations.pipCache),
        ]

        var items: [CleanableItem] = []
        for (name, path) in caches {
            if let item = makeCleanableItem(
                at: path,
                displayName: name,
                userEntries: userEntries
            ) {
                items.append(item)
            }
        }

        return CleanCategory(
            name: "Developer Caches",
            icon: "chevron.left.forwardslash.chevron.right",
            description: "Package manager caches",
            items: items
        )
    }

    func scanDSStores(userEntries: Set<String>) async -> CleanCategory {
        var items: [CleanableItem] = []
        let home = locations.home
        let skipDirs: Set<String> = [".Trash", "Library", ".git"]

        guard let enumerator = fileManager.enumerator(
            at: home,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return CleanCategory(
                name: ".DS_Store Files",
                icon: "doc.badge.gearshape",
                description: "Finder metadata files",
                items: []
            )
        }

        while let url = enumerator.nextObject() as? URL {
            let relativePath = url.path.replacingOccurrences(of: home.path, with: "")
            let topComponent = relativePath.split(separator: "/").first.map(String.init) ?? ""

            if skipDirs.contains(topComponent) {
                enumerator.skipDescendants()
                continue
            }

            if url.lastPathComponent == ".DS_Store",
               !ExclusionList.isExcluded(url.deletingLastPathComponent(), userEntries: userEntries)
            {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                items.append(CleanableItem(
                    path: url,
                    name: ".DS_Store (\(url.deletingLastPathComponent().lastPathComponent))",
                    size: Int64(size)
                ))
            }
        }

        return CleanCategory(
            name: ".DS_Store Files",
            icon: "doc.badge.gearshape",
            description: "Finder metadata files scattered across your folders",
            items: items
        )
    }

    func scanMailAttachments(userEntries: Set<String>) async -> CleanCategory? {
        guard fileManager.isReadableFile(atPath: locations.mailAttachments.path),
              !ExclusionList.isExcluded(locations.mailAttachments, userEntries: userEntries)
        else {
            return nil
        }
        guard let item = makeCleanableItem(
            at: locations.mailAttachments,
            displayName: "Mail Downloads",
            userEntries: userEntries
        ) else {
            return nil
        }

        return CleanCategory(
            name: "Mail Attachments",
            icon: "envelope",
            description: "Downloaded email attachments",
            items: [item]
        )
    }

    // MARK: - Size Calculation

    func directorySize(at url: URL) -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }

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

    // MARK: - Helpers

    private func enumerateDirectories(
        at url: URL,
        excluding: Set<String> = [],
        userEntries: Set<String>
    ) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [CleanableItem] = []
        for entry in contents {
            let name = entry.lastPathComponent
            if excluding.contains(name) { continue }
            if ExclusionList.isExcluded(entry, userEntries: userEntries) { continue }

            let size = directorySize(at: entry)
            guard size > 0 else { continue }

            let modDate = (try? entry.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? Date()

            items.append(CleanableItem(
                path: entry,
                size: size,
                modifiedDate: modDate
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    private func enumerateFiles(
        at url: URL,
        olderThan cutoff: Date,
        userEntries: Set<String>
    ) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: []
        ) else { return [] }

        var items: [CleanableItem] = []
        for entry in contents {
            if ExclusionList.isExcluded(entry, userEntries: userEntries) { continue }
            guard let values = try? entry.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey]
            ) else { continue }

            let modDate = values.contentModificationDate ?? Date()
            guard modDate < cutoff else { continue }

            let size = Int64(values.fileSize ?? 0)
            guard size > 0 else { continue }

            items.append(CleanableItem(
                path: entry,
                size: size,
                modifiedDate: modDate
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    private func makeCleanableItem(
        at url: URL,
        displayName: String? = nil,
        userEntries: Set<String>
    ) -> CleanableItem? {
        guard fileManager.fileExists(atPath: url.path),
              !ExclusionList.isExcluded(url, userEntries: userEntries)
        else { return nil }

        let size = directorySize(at: url)
        guard size > 0 else { return nil }

        let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? Date()

        return CleanableItem(
            path: url,
            name: displayName ?? url.lastPathComponent,
            size: size,
            modifiedDate: modDate
        )
    }

    private func chromiumCachePaths(base: URL, fallbackToBase: Bool = false) -> [URL] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return fallbackToBase ? [base] : []
        }

        var paths: [URL] = []
        for entry in contents {
            let name = entry.lastPathComponent
            guard name == "Default" || name.hasPrefix("Profile ") else { continue }
            paths.append(entry.appendingPathComponent("Cache"))
            paths.append(entry.appendingPathComponent("Code Cache"))
        }

        if paths.isEmpty, fallbackToBase {
            paths.append(base)
        }

        return paths
    }
}

// MARK: - Progress

private enum ScanPhase {
    case systemCaches
    case browserCaches
    case logs
    case temporaryFiles
    case xcodeData
    case developerCaches
    case dsStoreFiles
    case mailAttachments

    var displayName: String {
        switch self {
        case .systemCaches: return "System Caches"
        case .browserCaches: return "Browser Caches"
        case .logs: return "System Logs"
        case .temporaryFiles: return "Temporary Files"
        case .xcodeData: return "Xcode Data"
        case .developerCaches: return "Developer Caches"
        case .dsStoreFiles: return ".DS_Store Files"
        case .mailAttachments: return "Mail Attachments"
        }
    }
}

enum ScanProgress {
    case scanning(category: String, progress: Double, foundSoFar: Int64)
    case complete(ScanResult)
}
