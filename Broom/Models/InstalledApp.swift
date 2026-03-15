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
    var associatedFiles: [CleanableItem]
    var lastUsedDate: Date?

    var totalSize: Int64 { bundleSize + associatedFiles.reduce(0) { $0 + $1.size } }
    var isProtected: Bool { isSystemApp || isAppleApp }
    var formattedTotalSize: String { SizeFormatter.format(totalSize) }

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
        associatedFiles: [CleanableItem] = [],
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
        self.associatedFiles = associatedFiles
        self.lastUsedDate = lastUsedDate
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
