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

    private let appInventory: AppInventory
    private let appUninstaller: AppUninstaller
    private var loadTask: Task<Void, Never>?

    init() {
        let inventory = AppInventory()
        self.appInventory = inventory
        self.appUninstaller = AppUninstaller(appInventory: inventory)
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
            let files = await appInventory.findAssociatedFiles(
                for: app.bundleIdentifier, appName: app.name
            )
            var updatedApp = app
            updatedApp.associatedFiles = files
            selectedApp = updatedApp

            if let idx = apps.firstIndex(where: { $0.id == app.id }) {
                apps[idx].associatedFiles = files
            }
        }
    }

    func prepareUninstall() {
        guard let app = selectedApp else { return }

        Task {
            let plan = await appUninstaller.prepareUninstall(app: app)
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

        Task {
            state = .uninstalling(progress: 0, currentItem: "")

            for await progress in appUninstaller.executeUninstall(plan: plan) {
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

        // Find in existing list or parse it
        if let existing = apps.first(where: { $0.bundlePath == url }) {
            selectApp(existing)
        }
    }

    func cancelUninstall() {
        showUninstallConfirmation = false
        showRunningAppAlert = false
        uninstallPlan = nil
    }
}
