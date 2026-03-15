import AppKit
import Foundation

struct InstalledApp: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let version: String
    let bundlePath: URL
    let bundleSize: Int64
    let icon: NSImage?
    let isSystemApp: Bool
    let isAppleApp: Bool
    var bundleIsSelected: Bool
    var associatedFiles: [CleanableItem]
    var associatedFilesLoaded: Bool
    var lastUsedDate: Date?

    var totalSize: Int64 { bundleSize + associatedFiles.reduce(0) { $0 + $1.size } }
    var selectedAssociatedSize: Int64 { associatedFiles.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var selectedTotalSize: Int64 { (bundleIsSelected ? bundleSize : 0) + selectedAssociatedSize }
    var selectedItemCount: Int { (bundleIsSelected ? 1 : 0) + associatedFiles.filter(\.isSelected).count }
    var isProtected: Bool { isSystemApp || isAppleApp }
    var formattedTotalSize: String { SizeFormatter.format(totalSize) }
    var formattedSelectedSize: String { SizeFormatter.format(selectedTotalSize) }

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        version: String = "",
        bundlePath: URL,
        bundleSize: Int64 = 0,
        icon: NSImage? = nil,
        isSystemApp: Bool = false,
        isAppleApp: Bool = false,
        bundleIsSelected: Bool = true,
        associatedFiles: [CleanableItem] = [],
        associatedFilesLoaded: Bool = false,
        lastUsedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.bundlePath = bundlePath
        self.bundleSize = bundleSize
        self.icon = icon
        self.isSystemApp = isSystemApp
        self.isAppleApp = isAppleApp
        self.bundleIsSelected = bundleIsSelected
        self.associatedFiles = associatedFiles
        self.associatedFilesLoaded = associatedFilesLoaded
        self.lastUsedDate = lastUsedDate
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
