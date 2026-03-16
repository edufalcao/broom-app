import Foundation

struct FileScannerLocations {
    let home: URL
    let userCaches: URL
    let downloads: URL
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
    let homebrewCellar: URL
    let npmCache: URL
    let yarnCache: URL
    let pipCache: URL
    let dockerData: URL
    let dockerConfig: URL
    let mailAttachments: URL

    static let live = FileScannerLocations(
        home: Constants.home,
        userCaches: Constants.userCaches,
        downloads: Constants.downloads,
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
        homebrewCellar: Constants.homebrewCellar,
        npmCache: Constants.npmCache,
        yarnCache: Constants.yarnCache,
        pipCache: Constants.pipCache,
        dockerData: Constants.dockerData,
        dockerConfig: Constants.dockerConfig,
        mailAttachments: Constants.mailAttachments
    )
}

actor FileScanner: ScanServing {
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
                let preferences = await self.currentPreferences()
                let executor = await self.makeExecutor()
                let phases = scanPhases(for: preferences)
                let totalSteps = Double(max(phases.count, 1))
                var completedCount = 0
                var totalFoundSoFar: Int64 = 0
                var resultsByPhase: [ScanPhase: CleanCategory] = [:]

                if let firstPhase = phases.first {
                    continuation.yield(.scanning(
                        category: firstPhase.displayName,
                        progress: 0,
                        foundSoFar: 0
                    ))
                }

                await withTaskGroup(of: (ScanPhase, CleanCategory?).self) { group in
                    for phase in phases {
                        group.addTask {
                            (phase, executor.runPhase(phase, preferences: preferences))
                        }
                    }

                    for await (phase, category) in group {
                        if Task.isCancelled { break }

                        if let category {
                            resultsByPhase[phase] = category
                            totalFoundSoFar += category.totalSize
                        }

                        completedCount += 1
                        continuation.yield(.scanning(
                            category: phase.displayName,
                            progress: Double(completedCount) / totalSteps,
                            foundSoFar: totalFoundSoFar
                        ))
                    }
                }

                let categories = phases.compactMap { resultsByPhase[$0] }
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

    private func currentPreferences() -> AppPreferences {
        preferencesProvider()
    }

    private func makeExecutor() -> FileScannerExecutor {
        FileScannerExecutor(locations: locations)
    }

    // MARK: - Category Scanners

    func scanDocker(userEntries: Set<String>) -> CleanCategory? {
        makeExecutor().scanDocker(userEntries: userEntries)
    }

    func scanHomebrewExtended(userEntries: Set<String>) -> CleanCategory? {
        makeExecutor().scanHomebrewExtended(userEntries: userEntries)
    }

    private nonisolated func scanPhases(for preferences: AppPreferences) -> [ScanPhase] {
        var phases: [ScanPhase] = [
            .systemCaches,
            .browserCaches,
            .logs,
            .temporaryFiles,
            .downloads,
        ]

        if preferences.showDeveloperCaches {
            phases.append(.xcodeData)
            phases.append(.developerCaches)
        }

        if preferences.scanDSStores {
            phases.append(.dsStoreFiles)
        }

        phases.append(.dockerData)
        phases.append(.homebrewExtended)
        phases.append(.mailAttachments)

        return phases
    }

}

private struct FileScannerExecutor {
    private let fileManager = FileManager.default
    let locations: FileScannerLocations

    func runPhase(
        _ phase: ScanPhase,
        preferences: AppPreferences
    ) -> CleanCategory? {
        switch phase {
        case .systemCaches:
            return scanSystemCaches(userEntries: preferences.safeListEntries)
        case .browserCaches:
            return scanBrowserCaches(userEntries: preferences.safeListEntries)
        case .logs:
            return scanLogs(userEntries: preferences.safeListEntries)
        case .temporaryFiles:
            return scanTempFiles(preferences: preferences)
        case .downloads:
            return scanDownloads(userEntries: preferences.safeListEntries)
        case .xcodeData:
            return scanXcode(userEntries: preferences.safeListEntries)
        case .developerCaches:
            return scanDeveloperCaches(userEntries: preferences.safeListEntries)
        case .dsStoreFiles:
            return scanDSStores(userEntries: preferences.safeListEntries)
        case .dockerData:
            return scanDocker(userEntries: preferences.safeListEntries)
        case .homebrewExtended:
            return scanHomebrewExtended(userEntries: preferences.safeListEntries)
        case .mailAttachments:
            return scanMailAttachments(userEntries: preferences.safeListEntries)
        }
    }

    func scanSystemCaches(userEntries: Set<String>) -> CleanCategory {
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

    func scanBrowserCaches(userEntries: Set<String>) -> CleanCategory {
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

    func scanLogs(userEntries: Set<String>) -> CleanCategory {
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

    func scanTempFiles(preferences: AppPreferences) -> CleanCategory {
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

    func scanDownloads(userEntries: Set<String>) -> CleanCategory? {
        guard let item = makeCleanableItem(
            at: locations.downloads,
            displayName: "Downloads Folder",
            userEntries: userEntries
        ) else {
            return nil
        }

        return CleanCategory(
            name: "Downloads",
            icon: "arrow.down.circle",
            description: "Awareness-only view of your Downloads folder",
            items: [item],
            defaultSelected: false
        )
    }

    func scanXcode(userEntries: Set<String>) -> CleanCategory? {
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

    func scanDeveloperCaches(userEntries: Set<String>) -> CleanCategory {
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

    func scanDSStores(userEntries: Set<String>) -> CleanCategory {
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

    func scanDocker(userEntries: Set<String>) -> CleanCategory? {
        var items: [CleanableItem] = []

        let dockerPaths: [(String, URL)] = [
            ("Docker VM Data", locations.dockerData),
            ("Docker Config", locations.dockerConfig),
        ]

        for (name, path) in dockerPaths {
            if let item = makeCleanableItem(at: path, displayName: name, userEntries: userEntries) {
                items.append(item)
            }
        }

        guard !items.isEmpty else { return nil }

        return CleanCategory(
            name: "Docker Data",
            icon: "cube.box",
            description: "Docker VM disk images and configuration",
            items: items
        )
    }

    func scanHomebrewExtended(userEntries: Set<String>) -> CleanCategory? {
        var items: [CleanableItem] = []

        // Homebrew cache (downloads)
        if let item = makeCleanableItem(
            at: locations.homebrewCache,
            displayName: "Homebrew Cache",
            userEntries: userEntries
        ) {
            items.append(item)
        }

        // Old Cellar versions — report but don't auto-select
        let cellar = locations.homebrewCellar
        if fileManager.fileExists(atPath: cellar.path),
           let formulas = try? fileManager.contentsOfDirectory(
               at: cellar, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
           ) {
            for formula in formulas {
                guard let versions = try? fileManager.contentsOfDirectory(
                    at: formula, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
                ), versions.count > 1 else { continue }

                // Keep the latest version, report older ones
                let sorted = versions.sorted { $0.lastPathComponent > $1.lastPathComponent }
                for oldVersion in sorted.dropFirst() {
                    let size = directorySize(at: oldVersion)
                    if size > 0 {
                        items.append(CleanableItem(
                            path: oldVersion,
                            name: "\(formula.lastPathComponent) \(oldVersion.lastPathComponent)",
                            size: size,
                            isSelected: false // Don't auto-select old formula versions
                        ))
                    }
                }
            }
        }

        guard !items.isEmpty else { return nil }

        return CleanCategory(
            name: "Homebrew",
            icon: "mug",
            description: "Homebrew cache and old formula versions",
            items: items,
            defaultSelected: false
        )
    }

    func scanMailAttachments(userEntries: Set<String>) -> CleanCategory? {
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
    case downloads
    case xcodeData
    case developerCaches
    case dsStoreFiles
    case dockerData
    case homebrewExtended
    case mailAttachments

    var displayName: String {
        switch self {
        case .systemCaches: return "System Caches"
        case .browserCaches: return "Browser Caches"
        case .logs: return "System Logs"
        case .temporaryFiles: return "Temporary Files"
        case .downloads: return "Downloads"
        case .xcodeData: return "Xcode Data"
        case .developerCaches: return "Developer Caches"
        case .dsStoreFiles: return ".DS_Store Files"
        case .dockerData: return "Docker Data"
        case .homebrewExtended: return "Homebrew"
        case .mailAttachments: return "Mail Attachments"
        }
    }
}

enum ScanProgress {
    case scanning(category: String, progress: Double, foundSoFar: Int64)
    case complete(ScanResult)
}
