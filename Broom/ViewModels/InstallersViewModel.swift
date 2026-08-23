import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
class InstallersViewModel {
    enum State: Equatable {
        case idle
        case scanning(filesFound: Int)
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

    var state: State = .idle
    var files: [LargeFile] = []
    var showCleanConfirmation = false

    private let scanner: InstallerScanning
    private let cleaner: CleanServing
    private var scanTask: Task<Void, Never>?

    init(
        scanner: InstallerScanning = InstallerScanner(),
        cleaner: CleanServing = FileCleaner()
    ) {
        self.scanner = scanner
        self.cleaner = cleaner
    }

    var sortedFiles: [LargeFile] {
        files.sorted { $0.size > $1.size }
    }

    var selectedCount: Int { files.filter(\.isSelected).count }
    var selectedSize: Int64 { files.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }

    func startScan() {
        scanTask?.cancel()
        files = []
        scanTask = Task {
            state = .scanning(filesFound: 0)

            for await progress in scanner.scan() {
                if Task.isCancelled { break }

                switch progress {
                case .scanning(let found):
                    self.state = .scanning(filesFound: found)
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

            // Installer cleanup is trash-only by design.
            for await progress in cleaner.clean(items: items, moveToTrash: true) {
                switch progress {
                case .phase, .progress: continue
                case .complete(let report):
                    freedBytes = report.freedBytes
                    cleaned = report.itemsCleaned
                }
            }

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
