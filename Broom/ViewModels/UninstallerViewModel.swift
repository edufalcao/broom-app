import AppKit
import Foundation
import SwiftUI

struct RunningAppController {
    let isRunning: (String) -> Bool
    let terminate: (String) -> Bool
    let forceTerminate: (String) -> Bool

    static let live = RunningAppController(
        isRunning: RunningAppDetector.isRunning(bundleIdentifier:),
        terminate: RunningAppDetector.terminate(bundleIdentifier:),
        forceTerminate: RunningAppDetector.forceTerminate(bundleIdentifier:)
    )
}

@MainActor
@Observable
class UninstallerViewModel {
    enum State: Equatable {
        case loading
        case ready
        case uninstalling(progress: Double, currentItem: String, phase: UninstallPhase?)
        case done(freedBytes: Int64, itemsCleaned: Int, itemsFailed: Int)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.ready, .ready): return true
            case (.uninstalling, .uninstalling): return true
            case (.done, .done): return true
            default: return false
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case lastUsed = "Last Used"
    }

    var state: State = .loading
    var apps: [InstalledApp] = []
    var selectedApp: InstalledApp?
    var searchText = ""
    var sortOrder: SortOrder = .name
    var uninstallPlan: UninstallPlan?
    var showUninstallConfirmation = false
    var showRunningAppAlert = false
    var showForceQuitAlert = false
    var moveToTrashForUninstall: Bool

    private let appInventory: AppInventoryServing
    private let appUninstaller: AppUninstalling
    private let preferencesProvider: () -> AppPreferences
    private let runningAppController: RunningAppController
    private var loadTask: Task<Void, Never>?

    init(
        appInventory: AppInventoryServing? = nil,
        appUninstaller: AppUninstalling? = nil,
        preferencesProvider: @escaping () -> AppPreferences = { AppPreferences() },
        runningAppController: RunningAppController = .live
    ) {
        let inventory = appInventory ?? AppInventory()
        self.appInventory = inventory
        self.appUninstaller = appUninstaller ?? AppUninstaller(appInventory: inventory)
        self.preferencesProvider = preferencesProvider
        self.runningAppController = runningAppController
        self.moveToTrashForUninstall = preferencesProvider().moveToTrash
    }

    var filteredApps: [InstalledApp] {
        var result = apps.filter { !$0.isSystemApp && !$0.isAppleApp }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.bundleIdentifier.lowercased().contains(query)
            }
        }

        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            result.sort { $0.totalSize > $1.totalSize }
        case .lastUsed:
            result.sort { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) }
        }

        return result
    }

    func loadApps() {
        guard state == .loading else { return }
        loadTask = Task {
            let loaded = await appInventory.loadAllApps()
            apps = loaded
            state = .ready
        }
    }

    func reloadApps() {
        selectedApp = nil
        state = .loading
        loadTask = Task {
            let loaded = await appInventory.loadAllApps()
            apps = loaded
            state = .ready
        }
    }

    func selectApp(_ app: InstalledApp) {
        selectedApp = app
        guard !app.associatedFilesLoaded else { return }
        Task {
            let files = await appInventory.findAssociatedFiles(
                for: app.bundleIdentifier,
                appName: app.name
            )
            var updatedApp = app
            updatedApp.associatedFiles = files
            updatedApp.associatedFilesLoaded = true
            selectedApp = updatedApp

            if let idx = apps.firstIndex(where: { $0.id == app.id }) {
                apps[idx] = updatedApp
            }
        }
    }

    func toggleBundleSelection() {
        guard var app = selectedApp else { return }
        app.bundleIsSelected.toggle()
        updateSelectedApp(app)
    }

    func toggleAssociatedFile(_ fileID: UUID) {
        guard var app = selectedApp,
              let index = app.associatedFiles.firstIndex(where: { $0.id == fileID })
        else { return }

        app.associatedFiles[index].isSelected.toggle()
        updateSelectedApp(app)
    }

    func prepareUninstall(for app: InstalledApp? = nil) {
        guard let app = app ?? selectedApp, !app.isProtected else { return }
        moveToTrashForUninstall = preferencesProvider().moveToTrash

        Task {
            let plan = await appUninstaller.prepareUninstall(app: app)
            guard plan.selectedCount > 0 else { return }
            uninstallPlan = plan

            if plan.isRunning {
                showRunningAppAlert = true
            } else {
                showUninstallConfirmation = true
            }
        }
    }

    func quitAndUninstall() {
        guard let plan = uninstallPlan else { return }
        let bundleIdentifier = plan.app.bundleIdentifier
        guard runningAppController.terminate(bundleIdentifier) else {
            showRunningAppAlert = false
            showForceQuitAlert = true
            return
        }

        // Give the app a moment to quit, then show confirmation
        Task {
            try? await Task.sleep(for: .seconds(2))
            showRunningAppAlert = false

            if runningAppController.isRunning(bundleIdentifier) {
                showForceQuitAlert = true
            } else {
                showUninstallConfirmation = true
            }
        }
    }

    func forceQuitAndUninstall() {
        guard let plan = uninstallPlan else { return }
        let bundleIdentifier = plan.app.bundleIdentifier
        _ = runningAppController.forceTerminate(bundleIdentifier)

        Task {
            try? await Task.sleep(for: .seconds(1))
            showForceQuitAlert = false

            if runningAppController.isRunning(bundleIdentifier) {
                cancelUninstall()
            } else {
                showUninstallConfirmation = true
            }
        }
    }

    func confirmUninstall() {
        guard let plan = uninstallPlan else { return }
        showUninstallConfirmation = false

        Task {
            state = .uninstalling(progress: 0, currentItem: "", phase: nil)
            var currentPhase: UninstallPhase?

            for await progress in appUninstaller.executeUninstall(
                plan: plan,
                moveToTrash: moveToTrashForUninstall
            ) {
                switch progress {
                case .phase(let phase):
                    currentPhase = phase
                    state = .uninstalling(
                        progress: 0,
                        currentItem: Self.phaseDescription(phase),
                        phase: phase
                    )
                case .progress(let current, let total, let path):
                    let pct = total > 0 ? Double(current) / Double(total) : 0
                    state = .uninstalling(progress: pct, currentItem: path, phase: currentPhase)
                case .complete(let report):
                    apps.removeAll { $0.id == plan.app.id }
                    selectedApp = nil
                    uninstallPlan = nil
                    state = .done(
                        freedBytes: report.freedBytes,
                        itemsCleaned: report.itemsCleaned,
                        itemsFailed: report.itemsFailed
                    )

                    try? await Task.sleep(for: .seconds(3))
                    state = .ready
                }
            }
        }
    }

    static func phaseDescription(_ phase: UninstallPhase) -> String {
        switch phase {
        case .unloadingLaunchItems: return "Unloading launch agents..."
        case .removingLoginItems: return "Removing login items..."
        case .deletingFiles: return "Removing files..."
        case .cleaningMetadata: return "Cleaning up metadata..."
        case .refreshingDatabase: return "Refreshing system database..."
        }
    }

    func handleAppDrop(url: URL) {
        guard url.pathExtension == "app" else { return }

        Task {
            let droppedApp = if let existing = apps.first(where: { $0.bundlePath == url }) {
                existing
            } else {
                await appInventory.loadApp(at: url)
            }

            guard let droppedApp else { return }

            if let index = apps.firstIndex(where: { $0.bundlePath == droppedApp.bundlePath }) {
                apps[index] = droppedApp
            } else {
                apps.append(droppedApp)
            }

            selectedApp = droppedApp

            if !droppedApp.isProtected {
                prepareUninstall(for: droppedApp)
            }
        }
    }

    func cancelUninstall() {
        showUninstallConfirmation = false
        showRunningAppAlert = false
        showForceQuitAlert = false
        uninstallPlan = nil
        moveToTrashForUninstall = preferencesProvider().moveToTrash
    }

    private func updateSelectedApp(_ app: InstalledApp) {
        selectedApp = app
        if let idx = apps.firstIndex(where: { $0.id == app.id }) {
            apps[idx] = app
        }
    }
}
