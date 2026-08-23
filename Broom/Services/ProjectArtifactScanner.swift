import Foundation

enum ProjectArtifactScanProgress: Sendable {
    case scanning(currentPath: String, artifactsFound: Int)
    case complete([ProjectGroup])
}

protocol ProjectArtifactScanning {
    nonisolated func scan() -> AsyncStream<ProjectArtifactScanProgress>
}

actor ProjectArtifactScanner: ProjectArtifactScanning {
    /// How deep to search for project roots below each search root.
    private let projectDiscoveryDepth = 4
    /// How deep below a project root to look for artifact directories
    /// (covers workspace/monorepo layouts like packages/app/node_modules).
    private let artifactSearchDepth = 2
    private static let discoverySkipDirs: Set<String> = [
        "node_modules", ".build", "DerivedData", "Pods", ".cache",
        "vendor", "dist", "build", "__pycache__",
    ]

    private let fileManager = FileManager.default
    private let rootsProvider: @Sendable () -> [URL]
    private let recencyCutoffProvider: @Sendable () -> Date

    init(
        rootsProvider: @escaping @Sendable () -> [URL] = { ProjectArtifactScanner.liveRoots() },
        recencyCutoffProvider: @escaping @Sendable () -> Date = {
            Date().addingTimeInterval(-Double(AppPreferences().installerMinAgeDays) * 86_400)
        }
    ) {
        self.rootsProvider = rootsProvider
        self.recencyCutoffProvider = recencyCutoffProvider
    }

    /// User roots win; when none are configured the fixed defaults apply.
    nonisolated static func liveRoots() -> [URL] {
        let custom = UserDefaults.standard.stringArray(forKey: Constants.projectArtifactRootsKey) ?? []
        if custom.isEmpty {
            return Constants.defaultProjectArtifactRoots
        }
        return custom.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
    }

    nonisolated func scan() -> AsyncStream<ProjectArtifactScanProgress> {
        AsyncStream { continuation in
            Task {
                for await progress in await self.collectGroups() {
                    continuation.yield(progress)
                }
                continuation.finish()
            }
        }
    }

    private func collectGroups() -> AsyncStream<ProjectArtifactScanProgress> {
        AsyncStream { continuation in
            Task {
                let classifier = RecencyClassifier(cutoff: recencyCutoffProvider())
                var groupsByPath: [URL: ProjectGroup] = [:]
                var found = 0

                for root in rootsProvider() where fileManager.fileExists(atPath: root.path) {
                    for project in discoverProjects(below: root) {
                        let artifacts = collectArtifacts(project: project, classifier: classifier)
                        if !artifacts.isEmpty {
                            found += artifacts.count
                            groupsByPath[project] = ProjectGroup(path: project, artifacts: artifacts)
                        }
                    }
                    continuation.yield(.scanning(
                        currentPath: root.lastPathComponent,
                        artifactsFound: found
                    ))
                }

                continuation.yield(.complete(groupsByPath.values.sorted { $0.totalSize > $1.totalSize }))
                continuation.finish()
            }
        }
    }

    // MARK: - Project Discovery

    /// Directories containing any project indicator, up to the discovery
    /// depth. Heavy artifact directories are not descended into while
    /// searching.
    private func discoverProjects(below root: URL) -> Set<URL> {
        var projects: Set<URL> = []

        func walk(directory: URL, depth: Int) {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            ) else { return }

            var hasIndicator = false
            for entry in contents {
                if Constants.projectIndicatorNames.contains(entry.lastPathComponent) {
                    hasIndicator = true
                    break
                }
            }

            if hasIndicator {
                projects.insert(directory)
            }

            guard depth < projectDiscoveryDepth else { return }
            for entry in contents where (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                let name = entry.lastPathComponent
                if name.hasPrefix(".") && name != ".github" { continue }
                if Self.discoverySkipDirs.contains(name) { continue }
                walk(directory: entry, depth: depth + 1)
            }
        }

        walk(directory: root, depth: 1)
        return projects
    }

    // MARK: - Artifact Collection

    /// Family-named directories at or below the project root (bounded), plus
    /// CACHEDIR.TAG-marked children of the project itself.
    private func collectArtifacts(project: URL, classifier: RecencyClassifier) -> [ProjectArtifact] {
        var paths: [URL] = []

        func walk(directory: URL, depth: Int) {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            ) else { return }

            for entry in contents {
                let name = entry.lastPathComponent
                guard (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
                guard Constants.projectArtifactFamilies.contains(name) else {
                    if depth < artifactSearchDepth, !name.hasPrefix(".") {
                        walk(directory: entry, depth: depth + 1)
                    }
                    continue
                }
                paths.append(entry)
            }
        }

        walk(directory: project, depth: 0)

        // CACHEDIR.TAG marks any directory as regenerable cache content.
        if let children = try? fileManager.contentsOfDirectory(
            at: project,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) {
            for child in children where (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                let tag = child.appendingPathComponent(Constants.cacheDirTag)
                if fileManager.fileExists(atPath: tag.path),
                   !Constants.projectArtifactFamilies.contains(child.lastPathComponent) {
                    paths.append(child)
                }
            }
        }

        var artifacts: [ProjectArtifact] = []
        for path in paths.sorted(by: { $0.path < $1.path }) {
            let size = directorySizePruningNestedArtifacts(at: path)
            guard size > 0 else { continue }
            artifacts.append(ProjectArtifact(
                path: path,
                size: size,
                recency: classifier.classify(at: path)
            ))
        }
        return artifacts
    }

    private func directorySizePruningNestedArtifacts(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey, .isDirectoryKey],
            options: []
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]
            ) else { continue }
            if values.isRegularFile == true {
                total += Int64(values.totalFileAllocatedSize ?? 0)
            } else if Constants.projectArtifactFamilies.contains(fileURL.lastPathComponent) {
                // Nested artifacts are their own rows; don't double-count them.
                enumerator.skipDescendants()
            }
        }
        return total
    }
}
