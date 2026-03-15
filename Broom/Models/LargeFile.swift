import Foundation

struct LargeFile: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let modifiedDate: Date
    var isSelected: Bool

    var formattedSize: String { SizeFormatter.format(size) }
    var directoryPath: String {
        path.deletingLastPathComponent().path
            .replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    init(
        id: UUID = UUID(),
        path: URL,
        name: String? = nil,
        size: Int64,
        modifiedDate: Date = Date(),
        isSelected: Bool = false
    ) {
        self.id = id
        self.path = path
        self.name = name ?? path.lastPathComponent
        self.size = size
        self.modifiedDate = modifiedDate
        self.isSelected = isSelected
    }
}
