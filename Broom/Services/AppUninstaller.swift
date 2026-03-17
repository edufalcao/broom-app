import AppKit
import Foundation
import os

struct UninstallPlan {
    let app: InstalledApp
    let filesToRemove: [CleanableItem]
    let totalSize: Int64
    let isRunning: Bool
    let isProtected: Bool

    var selectedCount: Int { filesToRemove.count }
}

enum UninstallPhase: Sendable {
    case unloadingLaunchItems
    case removingLoginItems
    case deletingFiles
    case cleaningMetadata
    case refreshingDatabase
}

actor AppUninstaller: AppUninstalling {
    private let appInventory: AppInventoryServing
    private let planner: UninstallArtifactPlanner
    private let launchServicesManager: LaunchServicesManager
    private let loginItemManager: LoginItemManager

    init(
        appInventory: AppInventoryServing,
        planner: UninstallArtifactPlanner = UninstallArtifactPlanner(),
        launchServicesManager: LaunchServicesManager = LaunchServicesManager(),
        loginItemManager: LoginItemManager = LoginItemManager()
    ) {
        self.appInventory = appInventory
        self.planner = planner
        self.launchServicesManager = launchServicesManager
        self.loginItemManager = loginItemManager
    }

    func prepareUninstall(app: InstalledApp) async -> UninstallPlan {
        let plannedArtifacts = planner.planArtifacts(for: app)

        var existingFiles = app.associatedFiles.filter(\.isSelected)
        if existingFiles.isEmpty && !app.associatedFilesLoaded {
            existingFiles = await appInventory.findAssociatedFiles(
                for: app.bundleIdentifier,
                appName: app.name
            )
        }

        var seen = Set<String>()
        var files: [CleanableItem] = []
        for item in plannedArtifacts {
            let key = item.path.standardizedFileURL.path
            if seen.insert(key).inserted {
                files.append(item)
            }
        }
        for item in existingFiles {
            let key = item.path.standardizedFileURL.path
            if seen.insert(key).inserted {
                files.append(item)
            }
        }

        if app.bundleIsSelected {
            let bundlePath = app.bundlePath.standardizedFileURL.path
            if seen.insert(bundlePath).inserted {
                let bundleItem = CleanableItem(
                    path: app.bundlePath,
                    name: "\(app.name).app",
                    size: app.bundleSize,
                    source: .appBundle
                )
                files.append(bundleItem)
            }
        }

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
        let launchServices = launchServicesManager
        let loginItems = loginItemManager

        return AsyncStream { continuation in
            Task {
                let startTime = Date()
                var freedBytes: Int64 = 0
                var cleaned = 0
                var failed = 0
                var errors: [CleanError] = []

                // --- Pre-delete: unload launch items and remove login items ---
                if !plan.isProtected {
                    let launchItemFiles = plan.filesToRemove.filter { $0.source == .launchItems }
                    if !launchItemFiles.isEmpty {
                        continuation.yield(.phase(.unloadingLaunchItems))
                        for item in launchItemFiles {
                            if item.path.path.contains("/LaunchDaemons/") {
                                loginItems.unloadLaunchDaemon(at: item.path)
                            } else {
                                loginItems.unloadLaunchAgent(at: item.path)
                            }
                        }
                    }

                    continuation.yield(.phase(.removingLoginItems))
                    _ = loginItems.removeLoginItems(matching: plan.app.bundleIdentifier)
                }

                // --- File removal: library files first, .app bundle last ---
                continuation.yield(.phase(.deletingFiles))
                let sorted = plan.filesToRemove.filter { $0.source != .appBundle } +
                    plan.filesToRemove.filter { $0.source == .appBundle }
                let total = sorted.count

                var blocked = 0

                for (index, item) in sorted.enumerated() {
                    continuation.yield(.progress(
                        current: index + 1,
                        total: total,
                        currentPath: item.name
                    ))

                    let result: DeleteResult
                    if moveToTrash {
                        result = SafeDelete.moveToTrash(item.path, context: .explicitUninstall, expectedSize: item.size)
                    } else {
                        result = SafeDelete.deletePermanently(item.path, context: .explicitUninstall, expectedSize: item.size)
                    }

                    switch result {
                    case .success(_, let bytes):
                        freedBytes += bytes
                        cleaned += 1
                    case .blocked(let path, let reason):
                        blocked += 1
                        errors.append(CleanError(path: path, reason: "Blocked: \(reason.rawValue)"))
                    case .failed(let path, let error):
                        failed += 1
                        errors.append(CleanError(path: path, reason: error))
                    }
                }

                // --- Post-delete: clean up system metadata ---
                if !plan.isProtected {
                    continuation.yield(.phase(.cleaningMetadata))
                    _ = launchServices.unregisterApp(at: plan.app.bundlePath)

                    continuation.yield(.phase(.refreshingDatabase))
                    _ = launchServices.refreshDatabase()
                }

                let report = CleanReport(
                    freedBytes: freedBytes,
                    itemsCleaned: cleaned,
                    itemsFailed: failed,
                    itemsBlocked: blocked,
                    errors: errors,
                    duration: Date().timeIntervalSince(startTime)
                )
                continuation.yield(.complete(report))
                continuation.finish()
            }
        }
    }
}
