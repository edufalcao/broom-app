import Foundation

enum ArtifactRecency: String, Sendable {
    case recent
    case old
    case uncertain

    var label: String {
        switch self {
        case .recent: return "Active"
        case .old: return "Old"
        case .uncertain: return "Unknown age"
        }
    }
}

/// A regenerable build artifact found inside a project directory.
/// Shared cache stores never appear here; those belong to the Cleaner.
struct ProjectArtifact: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let recency: ArtifactRecency
    var isSelected: Bool

    init(id: UUID = UUID(), path: URL, name: String? = nil, size: Int64, recency: ArtifactRecency) {
        self.id = id
        self.path = path
        self.name = name ?? path.lastPathComponent
        self.size = size
        self.recency = recency
        // Suppression-first: only confidently-old artifacts start selected.
        self.isSelected = recency == .old
    }

    var formattedSize: String { SizeFormatter.format(size) }
}

/// Artifacts grouped by the project directory that owns them.
struct ProjectGroup: Identifiable {
    let path: URL
    var artifacts: [ProjectArtifact]

    var id: URL { path }
    var name: String { path.lastPathComponent }
    var totalSize: Int64 { artifacts.reduce(0) { $0 + $1.size } }
}
