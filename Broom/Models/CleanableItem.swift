import Foundation

struct CleanableItem: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let modifiedDate: Date
    var isSelected: Bool
    let confidence: OrphanConfidence?

    var isDirectory: Bool { path.hasDirectoryPath }
    var formattedSize: String { SizeFormatter.format(size) }

    init(
        id: UUID = UUID(),
        path: URL,
        name: String? = nil,
        size: Int64,
        modifiedDate: Date = Date(),
        isSelected: Bool = true,
        confidence: OrphanConfidence? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name ?? path.lastPathComponent
        self.size = size
        self.modifiedDate = modifiedDate
        self.isSelected = isSelected
        self.confidence = confidence
    }
}
