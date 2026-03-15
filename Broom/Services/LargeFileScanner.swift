import Foundation

enum LargeFileScanProgress: Sendable {
    case scanning(currentPath: String, filesFound: Int, progress: Double)
    case complete([LargeFile])
}

actor LargeFileScanner {
    private let fileManager = FileManager.default

    private let skipDirectories: Set<String> = [
        ".Trash", ".git", "node_modules", ".build",
        "DerivedData", "Pods", ".cache",
    ]

    nonisolated func scan(
        root: URL,
        minimumSize: Int64
    ) -> AsyncStream<LargeFileScanProgress> {
        AsyncStream { continuation in
            Task {
                var files: [LargeFile] = []
                let skipPaths: Set<String> = [
                    root.appendingPathComponent("Library/Caches").path,
                    root.appendingPathComponent(".Trash").path,
                ]

                guard let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: [
                        .fileSizeKey, .isRegularFileKey,
                        .contentModificationDateKey, .isDirectoryKey,
                    ],
                    options: [.skipsPackageDescendants]
                ) else {
                    continuation.yield(.complete([]))
                    continuation.finish()
                    return
                }

                var scannedCount = 0

                while let url = enumerator.nextObject() as? URL {
                    if Task.isCancelled { break }

                    let name = url.lastPathComponent

                    // Skip hidden files/dirs (except we want to find large ones)
                    if name.hasPrefix(".") && self.skipDirectories.contains(name) {
                        enumerator.skipDescendants()
                        continue
                    }

                    // Skip known large cache paths
                    if skipPaths.contains(where: { url.path.hasPrefix($0) }) {
                        enumerator.skipDescendants()
                        continue
                    }

                    // Skip Library directory
                    if url.path == root.appendingPathComponent("Library").path {
                        enumerator.skipDescendants()
                        continue
                    }

                    guard let values = try? url.resourceValues(
                        forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey, .isDirectoryKey]
                    ) else { continue }

                    // Skip directories from skipDirectories set
                    if values.isDirectory == true, self.skipDirectories.contains(name) {
                        enumerator.skipDescendants()
                        continue
                    }

                    guard values.isRegularFile == true else { continue }

                    let size = Int64(values.fileSize ?? 0)
                    guard size >= minimumSize else { continue }

                    let modDate = values.contentModificationDate ?? Date()
                    files.append(LargeFile(
                        path: url,
                        size: size,
                        modifiedDate: modDate
                    ))

                    scannedCount += 1
                    if scannedCount % 5 == 0 {
                        continuation.yield(.scanning(
                            currentPath: url.deletingLastPathComponent().lastPathComponent,
                            filesFound: files.count,
                            progress: -1 // indeterminate
                        ))
                    }
                }

                files.sort { $0.size > $1.size }
                continuation.yield(.complete(files))
                continuation.finish()
            }
        }
    }
}
