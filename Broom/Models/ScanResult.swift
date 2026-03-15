import Foundation

struct ScanResult {
    var categories: [CleanCategory]
    var orphanedApps: [OrphanedApp]
    let scanDuration: TimeInterval
    let scanDate: Date

    var totalSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }

    var selectedSize: Int64 {
        categories.reduce(0) { $0 + $1.selectedSize }
    }

    var totalItems: Int {
        categories.reduce(0) { $0 + $1.itemCount }
    }

    var selectedItems: Int {
        categories.reduce(0) { $0 + $1.selectedCount }
    }
}
