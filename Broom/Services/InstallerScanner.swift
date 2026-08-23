import Foundation

struct InstallerScanLocations {
    let sources: [URL]
    let homebrewDownloads: URL?

    static let live = InstallerScanLocations(
        sources: [
            Constants.downloads,
            Constants.home.appendingPathComponent("Desktop"),
            Constants.home.appendingPathComponent("Documents"),
        ],
        homebrewDownloads: Constants.homebrewCache.appendingPathComponent("downloads")
    )
}

enum InstallerScanProgress: Sendable {
    case scanning(filesFound: Int)
    case complete([LargeFile])
}

protocol InstallerScanning {
    nonisolated func scan() -> AsyncStream<InstallerScanProgress>
}

actor InstallerScanner: InstallerScanning {
    private static let installerExtensions: Set<String> = ["dmg", "pkg", "mpkg", "iso", "xip"]
    private static let maxDepth = 2

    private let locations: InstallerScanLocations
    private let minAgeDaysProvider: @Sendable () -> Int
    private let mountedPathsProvider: @Sendable () -> Set<String>

    init(
        locations: InstallerScanLocations = .live,
        minAgeDaysProvider: @escaping @Sendable () -> Int = { AppPreferences().installerMinAgeDays },
        mountedPathsProvider: @escaping @Sendable () -> Set<String> = { InstallerScanner.mountedDiskImagePaths() }
    ) {
        self.locations = locations
        self.minAgeDaysProvider = minAgeDaysProvider
        self.mountedPathsProvider = mountedPathsProvider
    }

    nonisolated func scan() -> AsyncStream<InstallerScanProgress> {
        AsyncStream { continuation in
            Task {
                for await progress in await self.collectInstallers() {
                    continuation.yield(progress)
                }
                continuation.finish()
            }
        }
    }

    private func collectInstallers() -> AsyncStream<InstallerScanProgress> {
        AsyncStream { continuation in
            Task {
                let fileManager = FileManager.default
                let minAgeDays = await self.minAgeDaysProvider()
                let cutoff = Date().addingTimeInterval(-Double(minAgeDays) * 86_400)
                let mounted = await self.mountedPathsProvider()

                var roots = locations.sources
                if let homebrewDownloads = locations.homebrewDownloads {
                    roots.append(homebrewDownloads)
                }

                var installers: [LargeFile] = []
                for root in roots {
                    for file in regularFiles(upToDepth: Self.maxDepth, below: root) {
                        guard isInstaller(file, cutoff: cutoff, mountedPaths: mounted) else { continue }
                        let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        guard size > 0 else { continue }
                        let modDate = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?
                            .contentModificationDate ?? Date()
                        installers.append(LargeFile(path: file, size: Int64(size), modifiedDate: modDate))
                    }
                    continuation.yield(.scanning(filesFound: installers.count))
                }

                continuation.yield(.complete(installers.sorted { $0.size > $1.size }))
                continuation.finish()
            }
        }
    }

    /// Regular files at depth 1 or 2 relative to the root (the root itself
    /// and one level of subdirectories).
    private func regularFiles(upToDepth maxDepth: Int, below root: URL) -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []

        func walk(directory: URL, depth: Int) {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            for entry in contents {
                let values = try? entry.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
                if values?.isRegularFile == true {
                    files.append(entry)
                } else if values?.isDirectory == true, depth < maxDepth,
                          !ExclusionList.isExcluded(entry, userEntries: []) {
                    walk(directory: entry, depth: depth + 1)
                }
            }
        }

        walk(directory: root, depth: 1)
        return files
    }

    private func isInstaller(_ url: URL, cutoff: Date, mountedPaths: Set<String>) -> Bool {
        let ext = url.pathExtension.lowercased()

        // Mounted disk images are in use regardless of age.
        if ext == "dmg" || ext == "iso" {
            let normalized = url.path.replacingOccurrences(of: "/private/", with: "/")
            if mountedPaths.contains(normalized) || mountedPaths.contains(url.path) { return false }
        }

        if Self.installerExtensions.contains(ext) {
            return passesAgeGate(url, cutoff: cutoff)
        }

        if ext == "zip" {
            guard ZipInspector.looksLikeInstallerArchive(at: url) else { return false }
            return passesAgeGate(url, cutoff: cutoff)
        }

        return false
    }

    private func passesAgeGate(_ url: URL, cutoff: Date) -> Bool {
        let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? Date()
        return modDate < cutoff
    }

    /// Disk images currently attached to the system, resolved from hdiutil.
    private static func mountedDiskImagePaths() -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["info", "-json"]
        process.standardOutput = Pipe()
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return []
        }

        let outputPipe = process.standardOutput as! Pipe
        var output = Data()
        while process.isRunning {
            output.append(outputPipe.fileHandleForReading.availableData)
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [] }

        guard let info = try? JSONSerialization.jsonObject(with: output) as? [String: Any],
              let images = info["images"] as? [[String: Any]] else { return [] }

        var paths: Set<String> = []
        for image in images {
            if let path = image["image-path"] as? String {
                paths.insert((path as NSString).standardizingPath)
            }
        }
        return paths
    }
}
