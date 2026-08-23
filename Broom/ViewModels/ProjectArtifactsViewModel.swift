import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
class ProjectArtifactsViewModel {
    enum State: Equatable {
        case idle
        case scanning(currentPath: String, artifactsFound: Int)
        case results
        case cleaning(cleaned: Int, total: Int)
        case done(freedBytes: Int64, itemsCleaned: Int)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.scanning, .scanning): return true
            case (.results, .results): return true
            case (.cleaning, .cleaning): return true
            case (.done, .done): return true
            default: return false
            }
        }

        var isBusy: Bool {
            if case .scanning = self { return true }
            if case .cleaning = self { return true }
            return false
        }
    }

    var state: State = .idle
    var groups: [ProjectGroup] = []
    var showCleanConfirmation = false

    private let scanner: ProjectArtifactScanning
    private let cleaner: CleanServing
    private let recencyClassifierProvider: @Sendable () -> RecencyClassifier
    private var scanTask: Task<Void, Never>?

    init(
        scanner: ProjectArtifactScanning = ProjectArtifactScanner(),
        cleaner: CleanServing = FileCleaner(),
        recencyClassifierProvider: @escaping @Sendable () -> RecencyClassifier = {
            RecencyClassifier(cutoff: Date().addingTimeInterval(-7 * 86_400))
        }
    ) {
        self.scanner = scanner
        self.cleaner = cleaner
        self.recencyClassifierProvider = recencyClassifierProvider
    }

    var allArtifacts: [ProjectArtifact] {
        groups.flatMap(\.artifacts)
    }

    var selectedArtifacts: [ProjectArtifact] {
        allArtifacts.filter(\.isSelected)
    }

    var selectedSize: Int64 { selectedArtifacts.reduce(0) { $0 + $1.size } }
    var totalSize: Int64 { allArtifacts.reduce(0) { $0 + $1.size } }

    func startScan() {
        scanTask?.cancel()
        groups = []
        scanTask = Task {
            state = .scanning(currentPath: "", artifactsFound: 0)

            for await progress in scanner.scan() {
                if Task.isCancelled { break }

                switch progress {
                case .scanning(let path, let found):
                    self.state = .scanning(currentPath: path, artifactsFound: found)
                case .complete(let results):
                    self.groups = results
                    self.state = .results
                }
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        state = .idle
    }

    func toggleArtifact(_ id: UUID) {
        mutateArtifact(id: id) { artifact in
            artifact.isSelected.toggle()
        }
    }

    /// Group header action: sets an explicit target state instead of blindly
    /// toggling every row.
    func setGroup(_ group: ProjectGroup, selected: Bool) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        for i in groups[index].artifacts.indices {
            groups[index].artifacts[i].isSelected = selected
        }
    }

    func startClean() {
        guard !selectedArtifacts.isEmpty else { return }
        showCleanConfirmation = true
    }

    func confirmClean() {
        // Delete-time re-check: drop anything that went active since scan.
        let classifier = recencyClassifierProvider()
        let confirmed = selectedArtifacts.filter { artifact in
            !classifier.isActive(at: artifact.path)
        }

        guard !confirmed.isEmpty else {
            state = .done(freedBytes: 0, itemsCleaned: 0)
            return
        }

        let items = confirmed.map {
            CleanableItem(path: $0.path, name: $0.name, size: $0.size)
        }

        scanTask = Task {
            var freedBytes: Int64 = 0
            var cleaned = 0

            for await progress in cleaner.clean(items: items, moveToTrash: true) {
                switch progress {
                case .progress(let current, let total, _):
                    self.state = .cleaning(cleaned: current, total: total)
                case .phase:
                    continue
                case .complete(let report):
                    freedBytes = report.freedBytes
                    cleaned = report.itemsCleaned
                }
            }

            removeArtifacts(paths: Set(confirmed.map(\.path)))
            self.state = .done(freedBytes: freedBytes, itemsCleaned: cleaned)
        }
    }

    private func removeArtifacts(paths: Set<URL>) {
        for gi in groups.indices {
            groups[gi].artifacts.removeAll { paths.contains($0.path) }
        }
        groups.removeAll { $0.artifacts.isEmpty }
    }

    private func mutateArtifact(id: UUID, _ mutation: (inout ProjectArtifact) -> Void) {
        for gi in groups.indices {
            if let ai = groups[gi].artifacts.firstIndex(where: { $0.id == id }) {
                mutation(&groups[gi].artifacts[ai])
                return
            }
        }
    }

    func reset() {
        groups = []
        state = .idle
    }

    func revealInFinder(_ artifact: ProjectArtifact) {
        NSWorkspace.shared.activateFileViewerSelecting([artifact.path])
    }
}
