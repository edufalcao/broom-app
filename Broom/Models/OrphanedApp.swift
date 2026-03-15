import Foundation

struct OrphanedApp: Identifiable {
    let id: UUID
    let appName: String
    let bundleIdentifier: String?
    let confidence: OrphanConfidence
    var locations: [CleanableItem]

    var totalSize: Int64 { locations.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { locations.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var locationCount: Int { locations.count }
    var selectedCount: Int { locations.filter(\.isSelected).count }
    var isSelected: Bool { !locations.isEmpty && selectedCount == locationCount }

    init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String? = nil,
        confidence: OrphanConfidence,
        locations: [CleanableItem]
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.confidence = confidence
        self.locations = locations
    }
}

enum OrphanConfidence: String, CaseIterable {
    case high
    case medium
    case low
}
