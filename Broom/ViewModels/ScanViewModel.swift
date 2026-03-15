import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
class ScanViewModel {
    // MARK: - State

    enum State: Equatable {
        case idle
        case scanning(progress: Double, currentCategory: String, foundSoFar: Int64)
        case results
        case cleaning(progress: Double, currentItem: String, cleanedCount: Int, totalCount: Int)
        case done(freedBytes: Int64, itemsCleaned: Int, itemsFailed: Int)
        case error(message: String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.scanning, .scanning): return true
            case (.results, .results): return true
            case (.cleaning, .cleaning): return true
            case (.done, .done): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }

        var isBusy: Bool {
            switch self {
            case .scanning, .cleaning: return true
            default: return false
            }
        }
    }

    var state: State = .idle
    var scanResult: ScanResult?

    var selectedSize: Int64 { scanResult?.selectedSize ?? 0 }
    var selectedItems: Int { scanResult?.selectedItems ?? 0 }
    var confirmationSize: Int64 { pendingCleanItems.reduce(0) { $0 + $1.size } }
    var confirmationItems: Int { pendingCleanItems.count }

    var showCleanConfirmation = false
    var showRunningAppsAlert = false
    var runningAppsInSelection: [String] = []

    private let scanner: ScanServing
    private let cleaner: CleanServing
    private let orphanDetector: OrphanDetecting
    private let preferencesProvider: () -> AppPreferences
    private var scanTask: Task<Void, Never>?
    private var pendingCleanItems: [CleanableItem] = []

    init(
        scanner: ScanServing = FileScanner(),
        cleaner: CleanServing = FileCleaner(),
        orphanDetector: OrphanDetecting? = nil,
        preferencesProvider: @escaping @Sendable () -> AppPreferences = { AppPreferences() }
    ) {
        self.scanner = scanner
        self.cleaner = cleaner
        let inventory = AppInventory()
        self.orphanDetector = orphanDetector ?? OrphanDetector(
            appInventory: inventory,
            preferencesProvider: preferencesProvider
        )
        self.preferencesProvider = preferencesProvider
    }

    // MARK: - Scan

    func startScan() {
        scanTask?.cancel()
        scanTask = Task {
            state = .scanning(progress: 0, currentCategory: "", foundSoFar: 0)

            for await progress in scanner.scanAll() {
                if Task.isCancelled { break }

                switch progress {
                case .scanning(let category, let pct, let found):
                    self.state = .scanning(progress: pct, currentCategory: category, foundSoFar: found)
                case .complete(let result):
                    self.state = .scanning(
                        progress: 0.95,
                        currentCategory: "App Leftovers",
                        foundSoFar: result.totalSize
                    )
                    let orphans = await orphanDetector.detectOrphans()
                    var completedResult = result
                    completedResult.orphanedApps = orphans
                    self.scanResult = completedResult
                    self.state = .results
                    UserDefaults.standard.set(Date(), forKey: "lastScanDate")
                    NotificationManager.sendScanComplete(totalSize: completedResult.totalSize)
                    self.updateDockBadge(totalSize: completedResult.totalSize)
                }
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        state = .idle
    }

    // MARK: - Selection

    func toggleCategory(_ categoryId: UUID) {
        guard var result = scanResult,
              let index = result.categories.firstIndex(where: { $0.id == categoryId }) else { return }

        let newSelected = !result.categories[index].isSelected
        result.categories[index].isSelected = newSelected
        for i in result.categories[index].items.indices {
            result.categories[index].items[i].isSelected = newSelected
        }
        scanResult = result
    }

    func toggleItem(_ itemId: UUID, in categoryId: UUID) {
        guard var result = scanResult,
              let catIndex = result.categories.firstIndex(where: { $0.id == categoryId }),
              let itemIndex = result.categories[catIndex].items.firstIndex(where: { $0.id == itemId })
        else { return }

        result.categories[catIndex].items[itemIndex].isSelected.toggle()

        let allSelected = result.categories[catIndex].items.allSatisfy(\.isSelected)
        let noneSelected = result.categories[catIndex].items.allSatisfy { !$0.isSelected }
        result.categories[catIndex].isSelected = allSelected && !noneSelected

        scanResult = result
    }

    func toggleOrphan(_ orphanId: UUID) {
        guard var result = scanResult,
              let index = result.orphanedApps.firstIndex(where: { $0.id == orphanId }) else { return }

        let newSelected = !result.orphanedApps[index].isSelected
        for i in result.orphanedApps[index].locations.indices {
            result.orphanedApps[index].locations[i].isSelected = newSelected
        }
        scanResult = result
    }

    func toggleOrphanLocation(_ itemId: UUID, in orphanId: UUID) {
        guard var result = scanResult,
              let orphanIndex = result.orphanedApps.firstIndex(where: { $0.id == orphanId }),
              let locIndex = result.orphanedApps[orphanIndex].locations.firstIndex(where: { $0.id == itemId })
        else { return }

        result.orphanedApps[orphanIndex].locations[locIndex].isSelected.toggle()
        scanResult = result
    }

    func selectAll() {
        guard var result = scanResult else { return }
        for i in result.categories.indices {
            result.categories[i].isSelected = true
            for j in result.categories[i].items.indices {
                result.categories[i].items[j].isSelected = true
            }
        }
        scanResult = result
    }

    func deselectAll() {
        guard var result = scanResult else { return }
        for i in result.categories.indices {
            result.categories[i].isSelected = false
            for j in result.categories[i].items.indices {
                result.categories[i].items[j].isSelected = false
            }
        }
        for i in result.orphanedApps.indices {
            for j in result.orphanedApps[i].locations.indices {
                result.orphanedApps[i].locations[j].isSelected = false
            }
        }
        scanResult = result
    }

    // MARK: - Clean

    func startClean() {
        let selectedItems = selectedCleanItems()
        guard !selectedItems.isEmpty else { return }

        let preferences = preferencesProvider()
        let runningApps = RunningAppDetector.matchingApplications(for: selectedItems)

        pendingCleanItems = selectedItems
        runningAppsInSelection = runningApps.map {
            $0.localizedName.isEmpty ? $0.bundleIdentifier : $0.localizedName.capitalized
        }

        if preferences.skipRunningApps, !runningAppsInSelection.isEmpty {
            showRunningAppsAlert = true
        } else {
            showCleanConfirmation = true
        }
    }

    func skipRunningAppsAndConfirm() {
        let runningApps = RunningAppDetector.matchingApplications(for: pendingCleanItems)
        let filtered = pendingCleanItems.filter { item in
            !runningApps.contains { RunningAppDetector.matches(item: item, runningApplication: $0) }
        }

        pendingCleanItems = filtered
        runningAppsInSelection = []
        showRunningAppsAlert = false

        guard !filtered.isEmpty else { return }
        showCleanConfirmation = true
    }

    func cleanRunningAppsAnyway() {
        showRunningAppsAlert = false
        showCleanConfirmation = true
    }

    func confirmClean() {
        let selectedItems = pendingCleanItems.isEmpty ? selectedCleanItems() : pendingCleanItems

        guard !selectedItems.isEmpty else { return }
        let preferences = preferencesProvider()
        let moveToTrash = preferences.moveToTrash

        scanTask = Task {
            state = .cleaning(progress: 0, currentItem: "", cleanedCount: 0, totalCount: selectedItems.count)

            for await progress in cleaner.clean(items: selectedItems, moveToTrash: moveToTrash) {
                if Task.isCancelled { break }

                switch progress {
                case .progress(let current, let total, let path):
                    let pct = total > 0 ? Double(current) / Double(total) : 0
                    self.state = .cleaning(progress: pct, currentItem: path, cleanedCount: current, totalCount: total)
                case .complete(let report):
                    self.state = .done(
                        freedBytes: report.freedBytes,
                        itemsCleaned: report.itemsCleaned,
                        itemsFailed: report.itemsFailed
                    )
                    NotificationManager.sendCleanComplete(freedBytes: report.freedBytes)
                    pendingCleanItems = []
                    self.clearDockBadge()
                }
            }
        }
    }

    private func selectedCleanItems() -> [CleanableItem] {
        guard let result = scanResult else { return [] }

        var selectedItems: [CleanableItem] = []
        for category in result.categories {
            selectedItems.append(contentsOf: category.items.filter(\.isSelected))
        }
        for orphan in result.orphanedApps {
            selectedItems.append(contentsOf: orphan.locations.filter(\.isSelected))
        }
        return selectedItems
    }

    // MARK: - Reset

    func reset() {
        scanResult = nil
        pendingCleanItems = []
        runningAppsInSelection = []
        showCleanConfirmation = false
        showRunningAppsAlert = false
        state = .idle
        clearDockBadge()
    }

    // MARK: - Dock Badge

    private func updateDockBadge(totalSize: Int64) {
        NSApp.dockTile.badgeLabel = totalSize > 0 ? SizeFormatter.format(totalSize) : nil
    }

    private func clearDockBadge() {
        NSApp.dockTile.badgeLabel = nil
    }
}
