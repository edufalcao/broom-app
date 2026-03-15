import Foundation
import Testing
@testable import Broom

@Suite("CleanCategory")
struct CleanCategoryTests {
    @Test func totalSizeAggregatesAllItems() {
        let items = [
            CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100),
            CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 200),
            CleanableItem(path: URL(fileURLWithPath: "/tmp/c"), size: 300),
        ]
        let category = CleanCategory(
            name: "Test", icon: "folder", description: "Test category", items: items
        )
        #expect(category.totalSize == 600)
    }

    @Test func selectedSizeWithMixedSelection() {
        let items = [
            CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100, isSelected: true),
            CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 200, isSelected: false),
            CleanableItem(path: URL(fileURLWithPath: "/tmp/c"), size: 300, isSelected: true),
        ]
        let category = CleanCategory(
            name: "Test", icon: "folder", description: "Test category", items: items
        )
        #expect(category.selectedSize == 400)
        #expect(category.selectedCount == 2)
    }
}

@Suite("ScanResult")
struct ScanResultTests {
    @Test func totalSizeAggregatesCategoriesAndOrphans() {
        let categories = [
            CleanCategory(
                name: "Caches", icon: "folder", description: "",
                items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 1000)]
            ),
        ]
        let orphans = [
            OrphanedApp(
                appName: "OldApp", confidence: .high,
                locations: [CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 500)]
            ),
        ]
        let result = ScanResult(
            categories: categories, orphanedApps: orphans,
            scanDuration: 1.0, scanDate: Date()
        )
        #expect(result.totalSize == 1500)
        #expect(result.totalItems == 2)
    }
}

@Suite("OrphanedApp")
struct OrphanedAppTests {
    @Test func totalSizeAggregatesLocations() {
        let orphan = OrphanedApp(
            appName: "TestApp", confidence: .medium,
            locations: [
                CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100),
                CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 250),
            ]
        )
        #expect(orphan.totalSize == 350)
        #expect(orphan.locationCount == 2)
    }

    @Test func isSelectedWhenAllLocationsSelected() {
        let orphan = OrphanedApp(
            appName: "TestApp", confidence: .high,
            locations: [
                CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100, isSelected: true),
                CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 200, isSelected: true),
            ]
        )
        #expect(orphan.isSelected == true)
    }

    @Test func isNotSelectedWhenSomeLocationsDeselected() {
        let orphan = OrphanedApp(
            appName: "TestApp", confidence: .high,
            locations: [
                CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100, isSelected: true),
                CleanableItem(path: URL(fileURLWithPath: "/tmp/b"), size: 200, isSelected: false),
            ]
        )
        #expect(orphan.isSelected == false)
    }
}
