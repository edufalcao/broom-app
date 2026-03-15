import Foundation
import os

actor FileScanner {
    private let fileManager = FileManager.default

    // MARK: - Public API

    nonisolated func scanAll() -> AsyncStream<ScanProgress> {
        AsyncStream { continuation in
            Task {
                let startTime = Date()
                var categories: [CleanCategory] = []
                let totalSteps = 8.0
                var currentStep = 0.0

                func report(_ name: String) {
                    currentStep += 1
                    continuation.yield(.scanning(
                        category: name,
                        progress: currentStep / totalSteps,
                        foundSoFar: categories.reduce(0) { $0 + $1.totalSize }
                    ))
                }

                report("System Caches")
                let caches = await scanSystemCaches()
                if !caches.items.isEmpty { categories.append(caches) }

                report("Browser Caches")
                let browsers = await scanBrowserCaches()
                if !browsers.items.isEmpty { categories.append(browsers) }

                report("System Logs")
                let logs = await scanLogs()
                if !logs.items.isEmpty { categories.append(logs) }

                report("Temporary Files")
                let temp = await scanTempFiles()
                if !temp.items.isEmpty { categories.append(temp) }

                report("Xcode Data")
                if let xcode = await scanXcode() {
                    categories.append(xcode)
                }

                report("Developer Caches")
                let dev = await scanDeveloperCaches()
                if !dev.items.isEmpty { categories.append(dev) }

                report(".DS_Store Files")
                let dsStores = await scanDSStores()
                if !dsStores.items.isEmpty { categories.append(dsStores) }

                report("Mail Attachments")
                if let mail = await scanMailAttachments() {
                    categories.append(mail)
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

    func scanSystemCaches() async -> CleanCategory {
        let items = enumerateDirectories(at: Constants.userCaches, excluding: Constants.protectedCacheIdentifiers)
        return CleanCategory(
            name: "System Caches",
            icon: "internaldrive",
            description: "Per-app cache directories that are safe to delete",
            items: items
        )
    }

    func scanBrowserCaches() async -> CleanCategory {
        var items: [CleanableItem] = []

        let browserPaths: [(String, [URL])] = [
            ("Chrome", Constants.chromeCachePaths),
            ("Firefox", [Constants.firefoxCache]),
            ("Safari", [Constants.safariCache]),
            ("Arc", [Constants.arcCache]),
            ("Brave", [Constants.braveCache]),
            ("Edge", [Constants.edgeCache]),
        ]

        for (name, paths) in browserPaths {
            for path in paths {
                if let item = makeCleanableItem(at: path, displayName: name) {
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

    func scanLogs() async -> CleanCategory {
        var items: [CleanableItem] = []

        for path in [Constants.userLogs, Constants.systemLogs] {
            if let item = makeCleanableItem(at: path) {
                items.append(item)
            }
        }

        if let item = makeCleanableItem(at: Constants.diagnosticReports, displayName: "Crash Reports") {
            items.append(item)
        }

        return CleanCategory(
            name: "System Logs",
            icon: "doc.text",
            description: "Application and system log files",
            items: items
        )
    }

    func scanTempFiles() async -> CleanCategory {
        var items: [CleanableItem] = []
        let ageHours = UserDefaults.standard.object(forKey: "minTempFileAgeHours") as? Int ?? 168
        let cutoff = Date().addingTimeInterval(-Double(ageHours) * 3600)

        for dir in [Constants.userTmpDir, Constants.systemTmp] {
            let oldFiles = enumerateFiles(at: dir, olderThan: cutoff)
            items.append(contentsOf: oldFiles)
        }

        return CleanCategory(
            name: "Temporary Files",
            icon: "clock.arrow.circlepath",
            description: "Temporary files older than 24 hours",
            items: items
        )
    }

    func scanXcode() async -> CleanCategory? {
        var items: [CleanableItem] = []

        if let item = makeCleanableItem(at: Constants.xcodeDerivedData, displayName: "Derived Data") {
            items.append(item)
        }
        if let item = makeCleanableItem(at: Constants.xcodeArchives, displayName: "Archives") {
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

    func scanDeveloperCaches() async -> CleanCategory {
        let caches: [(String, URL)] = [
            ("Swift Package Manager", Constants.spmCache),
            ("CocoaPods", Constants.cocoapodsCache),
            ("Homebrew", Constants.homebrewCache),
            ("npm", Constants.npmCache),
            ("Yarn", Constants.yarnCache),
            ("pip", Constants.pipCache),
        ]

        var items: [CleanableItem] = []
        for (name, path) in caches {
            if let item = makeCleanableItem(at: path, displayName: name) {
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

    func scanDSStores() async -> CleanCategory {
        var items: [CleanableItem] = []
        let home = Constants.home
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

        for case let url as URL in enumerator {
            let relativePath = url.path.replacingOccurrences(of: home.path, with: "")
            let topComponent = relativePath.split(separator: "/").first.map(String.init) ?? ""

            if skipDirs.contains(topComponent) {
                enumerator.skipDescendants()
                continue
            }

            if url.lastPathComponent == ".DS_Store" {
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

    func scanMailAttachments() async -> CleanCategory? {
        guard fileManager.isReadableFile(atPath: Constants.mailAttachments.path) else {
            return nil
        }
        guard let item = makeCleanableItem(at: Constants.mailAttachments, displayName: "Mail Downloads") else {
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

    private func enumerateDirectories(at url: URL, excluding: Set<String> = []) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [CleanableItem] = []
        for entry in contents {
            let name = entry.lastPathComponent
            if excluding.contains(name) { continue }

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

    private func enumerateFiles(at url: URL, olderThan cutoff: Date) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: []
        ) else { return [] }

        var items: [CleanableItem] = []
        for entry in contents {
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

    private func makeCleanableItem(at url: URL, displayName: String? = nil) -> CleanableItem? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

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
}

// MARK: - Progress

enum ScanProgress {
    case scanning(category: String, progress: Double, foundSoFar: Int64)
    case complete(ScanResult)
}
