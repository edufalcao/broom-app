import Foundation

/// Classifies artifact directories as recent, old, or uncertain against a
/// modification-time threshold. Uncertainty is treated as protected
/// (suppression-first), matching Broom's orphan-detection philosophy.
struct RecencyClassifier {
    let cutoff: Date
    /// Bounds the recursive probe so huge trees can't stall a scan.
    var maxProbedEntries: Int = 20_000

    init(cutoff: Date, maxProbedEntries: Int = 20_000) {
        self.cutoff = cutoff
        self.maxProbedEntries = maxProbedEntries
    }

    func classify(at url: URL) -> ArtifactRecency {
        let topDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate
        if let topDate, topDate > cutoff { return .recent }

        return probeDescendants(of: url)
    }

    /// Re-check performed immediately before deletion: an artifact that was
    /// old at scan time but went active since must not be deleted.
    func isActive(at url: URL) -> Bool {
        classify(at: url) != .old
    }

    private func probeDescendants(of url: URL) -> ArtifactRecency {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            // Unreadable content is unknown territory.
            return .uncertain
        }

        var probed = 0
        while let child = enumerator.nextObject() as? URL {
            probed += 1
            if probed > maxProbedEntries {
                // Budget exhausted before proving the tree is quiet.
                return .uncertain
            }

            if Task.isCancelled { return .uncertain }

            let date = (try? child.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate
            if date == nil {
                return .uncertain
            }
            if let date, date > cutoff {
                return .recent
            }
        }

        return .old
    }
}
