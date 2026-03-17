import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
class LargeFilesViewModel {
    enum State: Equatable {
        case idle
        case scanning(filesFound: Int, currentPath: String)
        case results
        case done(freedBytes: Int64, itemsCleaned: Int)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.scanning, .scanning): return true
            case (.results, .results): return true
            case (.done, .done): return true
            default: return false
            }
        }

        var isBusy: Bool {
            if case .scanning = self { return true }
            return false
        }
    }

    enum SortOrder: String, CaseIterable {
        case size = "Size"
        case name = "Name"
        case modified = "Modified"
    }

    enum MinimumSize: Int64, CaseIterable {
        case mb100 = 104_857_600
        case mb250 = 262_144_000
        case mb500 = 524_288_000
        case gb1 = 1_073_741_824

        var label: String {
            switch self {
            case .mb100: return "100 MB"
            case .mb250: return "250 MB"
            case .mb500: return "500 MB"
            case .gb1: return "1 GB"
            }
        }
    }

    var state: State = .idle
    var files: [LargeFile] = []
    var sortOrder: SortOrder = .size
    var minimumSize: MinimumSize = .mb100
    var showCleanConfirmation = false

    private let scanner: LargeFileScanning
    private let cleaner: CleanServing
    private var scanTask: Task<Void, Never>?

    init(
        scanner: LargeFileScanning = LargeFileScanner(),
        cleaner: CleanServing = FileCleaner()
    ) {
        self.scanner = scanner
        self.cleaner = cleaner
    }

    var sortedFiles: [LargeFile] {
        switch sortOrder {
        case .size: return files.sorted { $0.size > $1.size }
        case .name: return files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .modified: return files.sorted { $0.modifiedDate > $1.modifiedDate }
        }
    }

    var selectedCount: Int { files.filter(\.isSelected).count }
    var selectedSize: Int64 { files.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }

    func startScan() {
        scanTask?.cancel()
        files = []
        scanTask = Task {
            state = .scanning(filesFound: 0, currentPath: "")

            for await progress in scanner.scan(root: Constants.home, minimumSize: minimumSize.rawValue) {
                if Task.isCancelled { break }

                switch progress {
                case .scanning(let path, let found, _):
                    self.state = .scanning(filesFound: found, currentPath: path)
                case .complete(let results):
                    self.files = results
                    self.state = .results
                }
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        state = .idle
    }

    func toggleFile(_ id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        files[index].isSelected.toggle()
    }

    func selectAll() {
        for i in files.indices { files[i].isSelected = true }
    }

    func deselectAll() {
        for i in files.indices { files[i].isSelected = false }
    }

    func startClean() {
        guard selectedCount > 0 else { return }
        showCleanConfirmation = true
    }

    func confirmClean() {
        let items = files.filter(\.isSelected).map {
            CleanableItem(path: $0.path, name: $0.name, size: $0.size, modifiedDate: $0.modifiedDate)
        }
        guard !items.isEmpty else { return }

        scanTask = Task {
            var freedBytes: Int64 = 0
            var cleaned = 0

            for await progress in cleaner.clean(items: items, moveToTrash: true) {
                switch progress {
                case .phase, .progress: continue
                case .complete(let report):
                    freedBytes = report.freedBytes
                    cleaned = report.itemsCleaned
                }
            }

            // Remove cleaned files from list
            let cleanedPaths = Set(items.map(\.path))
            self.files.removeAll { cleanedPaths.contains($0.path) }
            self.state = .done(freedBytes: freedBytes, itemsCleaned: cleaned)
        }
    }

    func reset() {
        files = []
        state = .idle
    }

    func revealInFinder(_ file: LargeFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.path])
    }
}
