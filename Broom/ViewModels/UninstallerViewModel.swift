import AppKit
import Foundation
import SwiftUI

@Observable
class UninstallerViewModel {
    enum State: Equatable {
        case loading
        case ready
        case uninstalling(progress: Double, currentItem: String)
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
    var moveToTrashForUninstall: Bool

    private let appInventory: AppInventoryServing
    private let appUninstaller: AppUninstalling
    private let preferencesProvider: () -> AppPreferences
    private var loadTask: Task<Void, Never>?

    init(
        appInventory: AppInventoryServing? = nil,
        appUninstaller: AppUninstalling? = nil,
        preferencesProvider: @escaping () -> AppPreferences = { AppPreferences() }
    ) {
        let inventory = appInventory ?? AppInventory()
        self.appInventory = inventory
        self.appUninstaller = appUninstaller ?? AppUninstaller(appInventory: inventory)
        self.preferencesProvider = preferencesProvider
        self.moveToTrashForUninstall = preferencesProvider().moveToTrash
    }

    var filteredApps: [InstalledApp] {
        var result = apps.filter { !$0.isSystemApp }

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
        Task {
            var updatedApp = app
            if !app.associatedFilesLoaded {
                let files = await appInventory.findAssociatedFiles(
                    for: app.bundleIdentifier,
                    appName: app.name
                )
                updatedApp.associatedFiles = files
                updatedApp.associatedFilesLoaded = true
            }
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
        _ = RunningAppDetector.terminate(bundleIdentifier: plan.app.bundleIdentifier)

        // Give the app a moment to quit, then show confirmation
        Task {
            try? await Task.sleep(for: .seconds(2))
            showRunningAppAlert = false
            showUninstallConfirmation = true
        }
    }

    func confirmUninstall() {
        guard let plan = uninstallPlan else { return }
        showUninstallConfirmation = false

        Task {
            state = .uninstalling(progress: 0, currentItem: "")

            for await progress in appUninstaller.executeUninstall(
                plan: plan,
                moveToTrash: moveToTrashForUninstall
            ) {
                switch progress {
                case .progress(let current, let total, let path):
                    let pct = total > 0 ? Double(current) / Double(total) : 0
                    state = .uninstalling(progress: pct, currentItem: path)
                case .complete(let report):
                    // Remove from list
                    apps.removeAll { $0.id == plan.app.id }
                    selectedApp = nil
                    uninstallPlan = nil
                    state = .done(
                        freedBytes: report.freedBytes,
                        itemsCleaned: report.itemsCleaned,
                        itemsFailed: report.itemsFailed
                    )

                    // Return to ready after a delay
                    try? await Task.sleep(for: .seconds(3))
                    state = .ready
                }
            }
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
