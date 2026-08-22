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
    let vivaldiCache: URL
    let operaCache: URL
    let yandexCacheBase: URL
    let orionCache: URL
    let zenCache: URL
    let cometCache: URL
    let heliumCache: URL
    let qqBrowserCache: URL
    let thunderbirdCache: URL
    let diaCacheBase: URL
    let savedApplicationState: URL
    let messagesStickerCache: URL
    let messagesPreviewStickerCache: URL
    let cargoRegistryCache: URL
    let bunInstallCache: URL
    let corepackCacheCandidates: [URL]
    let rbenvCache: URL
    let gemSpecsCache: URL
    let bundlerCache: URL
    let simulatorCaches: URL
    let simulatorDevices: URL
    let simulatorLogs: URL

    init(
        home: URL,
        userCaches: URL,
        downloads: URL,
        chromeCacheBase: URL,
        firefoxCache: URL,
        safariCache: URL,
        arcCache: URL,
        braveCacheBase: URL,
        edgeCacheBase: URL,
        userLogs: URL,
        systemLogs: URL,
        diagnosticReports: URL,
        userTmpDir: URL,
        systemTmp: URL,
        xcodeDerivedData: URL,
        xcodeArchives: URL,
        spmCache: URL,
        cocoapodsCache: URL,
        homebrewCache: URL,
        homebrewCellar: URL,
        npmCache: URL,
        yarnCache: URL,
        pipCache: URL,
        dockerData: URL,
        dockerConfig: URL,
        mailAttachments: URL,
        // Enriched categories default to their live system paths so older
        // test fixtures stay valid.
        vivaldiCache: URL = Constants.vivaldiCache,
        operaCache: URL = Constants.operaCache,
        yandexCacheBase: URL = Constants.yandexCacheBase,
        orionCache: URL = Constants.orionCache,
        zenCache: URL = Constants.zenCache,
        cometCache: URL = Constants.cometCache,
        heliumCache: URL = Constants.heliumCache,
        qqBrowserCache: URL = Constants.qqBrowserCache,
        thunderbirdCache: URL = Constants.thunderbirdCache,
        diaCacheBase: URL = Constants.diaCacheBase,
        savedApplicationState: URL = Constants.savedApplicationState,
        messagesStickerCache: URL = Constants.messagesStickerCache,
        messagesPreviewStickerCache: URL = Constants.messagesPreviewStickerCache,
        cargoRegistryCache: URL = Constants.cargoRegistryCache,
        bunInstallCache: URL = Constants.bunInstallCache,
        corepackCacheCandidates: [URL] = Constants.corepackCacheCandidates,
        rbenvCache: URL = Constants.rbenvCache,
        gemSpecsCache: URL = Constants.gemSpecsCache,
        bundlerCache: URL = Constants.bundlerCache,
        simulatorCaches: URL = Constants.simulatorCaches,
        simulatorDevices: URL = Constants.simulatorDevices,
        simulatorLogs: URL = Constants.simulatorLogs
    ) {
        self.home = home
        self.userCaches = userCaches
        self.downloads = downloads
        self.chromeCacheBase = chromeCacheBase
        self.firefoxCache = firefoxCache
        self.safariCache = safariCache
        self.arcCache = arcCache
        self.braveCacheBase = braveCacheBase
        self.edgeCacheBase = edgeCacheBase
        self.userLogs = userLogs
        self.systemLogs = systemLogs
        self.diagnosticReports = diagnosticReports
        self.userTmpDir = userTmpDir
        self.systemTmp = systemTmp
        self.xcodeDerivedData = xcodeDerivedData
        self.xcodeArchives = xcodeArchives
        self.spmCache = spmCache
        self.cocoapodsCache = cocoapodsCache
        self.homebrewCache = homebrewCache
        self.homebrewCellar = homebrewCellar
        self.npmCache = npmCache
        self.yarnCache = yarnCache
        self.pipCache = pipCache
        self.dockerData = dockerData
        self.dockerConfig = dockerConfig
        self.mailAttachments = mailAttachments
        self.vivaldiCache = vivaldiCache
        self.operaCache = operaCache
        self.yandexCacheBase = yandexCacheBase
        self.orionCache = orionCache
        self.zenCache = zenCache
        self.cometCache = cometCache
        self.heliumCache = heliumCache
        self.qqBrowserCache = qqBrowserCache
        self.thunderbirdCache = thunderbirdCache
        self.diaCacheBase = diaCacheBase
        self.savedApplicationState = savedApplicationState
        self.messagesStickerCache = messagesStickerCache
        self.messagesPreviewStickerCache = messagesPreviewStickerCache
        self.cargoRegistryCache = cargoRegistryCache
        self.bunInstallCache = bunInstallCache
        self.corepackCacheCandidates = corepackCacheCandidates
        self.rbenvCache = rbenvCache
        self.gemSpecsCache = gemSpecsCache
        self.bundlerCache = bundlerCache
        self.simulatorCaches = simulatorCaches
        self.simulatorDevices = simulatorDevices
        self.simulatorLogs = simulatorLogs
    }

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
        mailAttachments: Constants.mailAttachments,
        vivaldiCache: Constants.vivaldiCache,
        operaCache: Constants.operaCache,
        yandexCacheBase: Constants.yandexCacheBase,
        orionCache: Constants.orionCache,
        zenCache: Constants.zenCache,
        cometCache: Constants.cometCache,
        heliumCache: Constants.heliumCache,
        qqBrowserCache: Constants.qqBrowserCache,
        thunderbirdCache: Constants.thunderbirdCache,
        diaCacheBase: Constants.diaCacheBase,
        savedApplicationState: Constants.savedApplicationState,
        messagesStickerCache: Constants.messagesStickerCache,
        messagesPreviewStickerCache: Constants.messagesPreviewStickerCache,
        cargoRegistryCache: Constants.cargoRegistryCache,
        bunInstallCache: Constants.bunInstallCache,
        corepackCacheCandidates: Constants.corepackCacheCandidates,
        rbenvCache: Constants.rbenvCache,
        gemSpecsCache: Constants.gemSpecsCache,
        bundlerCache: Constants.bundlerCache,
        simulatorCaches: Constants.simulatorCaches,
        simulatorDevices: Constants.simulatorDevices,
        simulatorLogs: Constants.simulatorLogs
    )
}

actor FileScanner: ScanServing {
    private let locations: FileScannerLocations
    private let preferencesProvider: @Sendable () -> AppPreferences
    private let runningBundleIDsProvider: @Sendable () -> Set<String>

    init(
        locations: FileScannerLocations = .live,
        preferencesProvider: @escaping @Sendable () -> AppPreferences = { AppPreferences() },
        runningBundleIDsProvider: @escaping @Sendable () -> Set<String> = { RunningAppDetector.runningBundleIdentifiers() }
    ) {
        self.locations = locations
        self.preferencesProvider = preferencesProvider
        self.runningBundleIDsProvider = runningBundleIDsProvider
    }

    // MARK: - Public API

    nonisolated func scanAll() -> AsyncStream<ScanProgress> {
        AsyncStream { continuation in
            Task {
                let startTime = Date()
                let preferences = await self.currentPreferences()
                let executor = await self.makeExecutor()
                let runningBundleIDs = runningBundleIDsProvider()
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
                            (phase, executor.runPhase(phase, preferences: preferences, runningBundleIDs: runningBundleIDs))
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
            phases.append(.simulatorData)
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
        preferences: AppPreferences,
        runningBundleIDs: Set<String> = []
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
        case .simulatorData:
            return scanSimulatorData(
                userEntries: preferences.safeListEntries,
                skipWhenToolsRunning: preferences.skipRunningApps,
                runningBundleIDs: runningBundleIDs
            )
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
        var items = enumerateDirectories(
            at: locations.userCaches,
            excluding: Constants.protectedCacheIdentifiers,
            userEntries: userEntries
        )

        let explicitTargets: [(String, URL)] = [
            ("Saved Application State", locations.savedApplicationState),
            ("Messages Sticker Cache", locations.messagesStickerCache),
            ("Messages Preview Cache", locations.messagesPreviewStickerCache),
        ]
        for (name, path) in explicitTargets {
            if let item = makeCleanableItem(at: path, displayName: name, userEntries: userEntries) {
                items.append(item)
            }
        }

        return CleanCategory(
            name: "System Caches",
            icon: "internaldrive",
            description: "Per-app cache directories that are safe to delete",
            items: items.sorted { $0.size > $1.size }
        )
    }

    func scanBrowserCaches(userEntries: Set<String>) -> CleanCategory {
        var items: [CleanableItem] = []

        let browserPaths: [(String, [LabeledPath])] = [
            ("Chrome", chromiumCachePaths(base: locations.chromeCacheBase)),
            ("Firefox", [LabeledPath(locations.firefoxCache, label: nil)]),
            ("Safari", [LabeledPath(locations.safariCache, label: nil)]),
            ("Arc", [LabeledPath(locations.arcCache, label: nil)]),
            ("Brave", chromiumCachePaths(base: locations.braveCacheBase)),
            ("Edge", chromiumCachePaths(base: locations.edgeCacheBase, fallbackToBase: true)),
            ("Vivaldi", [LabeledPath(locations.vivaldiCache, label: nil)]),
            ("Opera", [LabeledPath(locations.operaCache, label: nil)]),
            ("Yandex", chromiumCachePaths(base: locations.yandexCacheBase, fallbackToBase: true)),
            ("Orion", [LabeledPath(locations.orionCache, label: nil)]),
            ("Zen", [LabeledPath(locations.zenCache, label: nil)]),
            ("Comet", [LabeledPath(locations.cometCache, label: nil)]),
            ("Helium", [LabeledPath(locations.heliumCache, label: nil)]),
            ("QQ Browser", [LabeledPath(locations.qqBrowserCache, label: nil)]),
            ("Thunderbird", [LabeledPath(locations.thunderbirdCache, label: nil)]),
            ("Dia", chromiumCachePaths(base: locations.diaCacheBase, fallbackToBase: true)),
        ]

        for (name, paths) in browserPaths {
            for path in paths {
                let displayName = path.label.map { "\(name) — \($0)" } ?? name
                if let item = makeCleanableItem(
                    at: path.url,
                    displayName: displayName,
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
        var caches: [(String, URL)] = [
            ("Swift Package Manager", locations.spmCache),
            ("CocoaPods", locations.cocoapodsCache),
            ("Homebrew", locations.homebrewCache),
            ("npm", locations.npmCache),
            ("Yarn", locations.yarnCache),
            ("pip", locations.pipCache),
            ("Cargo Registry", locations.cargoRegistryCache),
            ("Bun", locations.bunInstallCache),
            ("rbenv Downloads", locations.rbenvCache),
            ("RubyGems Specs", locations.gemSpecsCache),
            ("Bundler", locations.bundlerCache),
        ]
        for candidate in locations.corepackCacheCandidates {
            caches.append(("Corepack", candidate))
        }

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
            description: "Package manager and toolchain caches",
            items: items
        )
    }

    func scanSimulatorData(
        userEntries: Set<String>,
        skipWhenToolsRunning: Bool,
        runningBundleIDs: Set<String>
    ) -> CleanCategory? {
        let toolBundleIDs: Set<String> = [
            "com.apple.dt.xcode",
            "com.apple.iphonesimulator",
        ]
        let normalizedRunningIDs = Set(runningBundleIDs.map { $0.lowercased() })
        if skipWhenToolsRunning,
           !normalizedRunningIDs.isDisjoint(with: toolBundleIDs) {
            return nil
        }

        var items: [CleanableItem] = []

        let fixedTargets: [(String, URL)] = [
            ("Simulator Caches", locations.simulatorCaches),
            ("Simulator Logs", locations.simulatorLogs),
        ]
        for (name, path) in fixedTargets {
            if let item = makeCleanableItem(at: path, displayName: name, userEntries: userEntries) {
                items.append(item)
            }
        }

        // Per-device temp directories are regenerable scratch space.
        if let devices = try? fileManager.contentsOfDirectory(
            at: locations.simulatorDevices,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for device in devices.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let tmpDir = device
                    .appendingPathComponent("data")
                    .appendingPathComponent("tmp")
                guard let item = makeCleanableItem(
                    at: tmpDir,
                    displayName: "Simulator Temp (\(device.lastPathComponent.prefix(8)))",
                    userEntries: userEntries
                ) else { continue }
                items.append(item)
            }
        }

        guard !items.isEmpty else { return nil }

        return CleanCategory(
            name: "Simulator Data",
            icon: "iphone.gen3",
            description: "Regenerable simulator caches, logs, and temp files",
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

    private func chromiumCachePaths(base: URL, fallbackToBase: Bool = false) -> [LabeledPath] {
        // Per-profile cache subdirs plus base-level CRX component caches.
        let profileSubdirs = [
            "Cache",
            "Code Cache",
            "GPUCache",
            "ShaderCache",
            "GrShaderCache",
            "DawnGraphiteCache",
            "DawnWebGPUCache",
        ]
        let baseSubdirs = ["component_crx_cache", "extensions_crx_cache"]

        var paths: [LabeledPath] = baseSubdirs.map { LabeledPath(base.appendingPathComponent($0), label: $0) }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            if fallbackToBase {
                paths.append(LabeledPath(base, label: nil))
            }
            return paths
        }

        for entry in contents {
            let name = entry.lastPathComponent
            guard name == "Default" || name.hasPrefix("Profile ") else { continue }
            for subdir in profileSubdirs {
                paths.append(LabeledPath(entry.appendingPathComponent(subdir), label: subdir))
            }
        }

        if !paths.contains(where: { $0.label == nil }), fallbackToBase {
            paths.append(LabeledPath(base, label: nil))
        }

        return paths
    }
}

/// A cache location paired with an optional display suffix distinguishing
/// it from sibling caches of the same app.
struct LabeledPath {
    let url: URL
    let label: String?

    init(_ url: URL, label: String? = nil) {
        self.url = url
        self.label = label
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
    case simulatorData
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
        case .simulatorData: return "Simulator Data"
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
