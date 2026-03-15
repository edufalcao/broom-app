import AppKit
import Foundation
import os

struct UninstallPlan {
    let app: InstalledApp
    let filesToRemove: [CleanableItem]
    let totalSize: Int64
    let isRunning: Bool
    let isProtected: Bool
}

actor AppUninstaller {
    private let appInventory: AppInventory

    init(appInventory: AppInventory) {
        self.appInventory = appInventory
    }

    func prepareUninstall(app: InstalledApp) async -> UninstallPlan {
        var files = await appInventory.findAssociatedFiles(
            for: app.bundleIdentifier,
            appName: app.name
        )

        // Add the .app bundle itself as the last item
        let bundleItem = CleanableItem(
            path: app.bundlePath,
            name: "\(app.name).app",
            size: app.bundleSize
        )
        files.append(bundleItem)

        let totalSize = files.reduce(0) { $0 + $1.size }
        let isRunning = RunningAppDetector.isRunning(bundleIdentifier: app.bundleIdentifier)

        return UninstallPlan(
            app: app,
            filesToRemove: files,
            totalSize: totalSize,
            isRunning: isRunning,
            isProtected: app.isProtected
        )
    }

    nonisolated func executeUninstall(plan: UninstallPlan, moveToTrash: Bool = true) -> AsyncStream<CleanProgress> {
        AsyncStream { continuation in
            Task {
                let startTime = Date()
                var freedBytes: Int64 = 0
                var cleaned = 0
                var failed = 0
                var errors: [CleanError] = []

                // Remove Library files first, .app bundle last
                let sorted = plan.filesToRemove.sorted { a, _ in
                    !a.path.pathExtension.lowercased().contains("app")
                }
                let total = sorted.count

                for (index, item) in sorted.enumerated() {
                    continuation.yield(.progress(
                        current: index,
                        total: total,
                        currentPath: item.name
                    ))

                    let result: Result<Void, Error>
                    if moveToTrash {
                        result = SafeDelete.moveToTrash(item.path)
                    } else {
                        result = SafeDelete.deletePermanently(item.path)
                    }

                    switch result {
                    case .success:
                        freedBytes += item.size
                        cleaned += 1
                    case .failure(let error):
                        failed += 1
                        errors.append(CleanError(path: item.path, reason: error.localizedDescription))
                    }
                }

                let report = CleanReport(
                    freedBytes: freedBytes,
                    itemsCleaned: cleaned,
                    itemsFailed: failed,
                    errors: errors,
                    duration: Date().timeIntervalSince(startTime)
                )
                continuation.yield(.complete(report))
                continuation.finish()
            }
        }
    }
}
