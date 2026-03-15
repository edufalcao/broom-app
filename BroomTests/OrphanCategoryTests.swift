import Foundation
import Testing
@testable import Broom

@Suite("Orphan as Category")
struct OrphanCategoryTests {
    @Test @MainActor func orphansConvertedToCategory() async {
        let orphanLocation = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/orphan/cache"),
            name: "Caches/com.old.app",
            size: 5000,
            isSelected: false
        )
        let orphan = OrphanedApp(
            appName: "OldApp",
            bundleIdentifier: "com.old.app",
            confidence: .high,
            locations: [orphanLocation]
        )

        let mockScanner = MockScanner {
            AsyncStream { continuation in
                let result = ScanResult(
                    categories: [
                        CleanCategory(
                            name: "System Caches", icon: "internaldrive", description: "",
                            items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/cache"), size: 1000)]
                        ),
                    ],
                    orphanedApps: [],
                    scanDuration: 0.1,
                    scanDate: Date()
                )
                continuation.yield(.complete(result))
                continuation.finish()
            }
        }

        let mockOrphanDetector = MockOrphanDetector(orphans: [orphan])

        let vm = ScanViewModel(
            scanner: mockScanner,
            orphanDetector: mockOrphanDetector
        )

        vm.startScan()
        await TestSupport.awaitCondition { vm.state == .results }

        // Should have 2 categories: System Caches + App Leftovers
        #expect(vm.scanResult?.categories.count == 2)

        let leftovers = vm.scanResult?.categories.first { $0.name == "App Leftovers" }
        #expect(leftovers != nil)
        #expect(leftovers?.items.count == 1)
        #expect(leftovers?.items[0].name.contains("OldApp") == true)
        #expect(leftovers?.items[0].confidence == .high)
        #expect(leftovers?.isSelected == false) // defaults to unselected
    }

    @Test @MainActor func orphanConfidencePreservedOnItems() async {
        let highOrphan = OrphanedApp(
            appName: "HighApp", bundleIdentifier: "com.high.app", confidence: .high,
            locations: [CleanableItem(path: URL(fileURLWithPath: "/tmp/h"), name: "data", size: 100, isSelected: false)]
        )
        let lowOrphan = OrphanedApp(
            appName: "LowApp", bundleIdentifier: nil, confidence: .low,
            locations: [CleanableItem(path: URL(fileURLWithPath: "/tmp/l"), name: "data", size: 200, isSelected: false)]
        )

        let mockScanner = MockScanner {
            AsyncStream { continuation in
                continuation.yield(.complete(ScanResult(categories: [], orphanedApps: [], scanDuration: 0.1, scanDate: Date())))
                continuation.finish()
            }
        }
        let mockOrphanDetector = MockOrphanDetector(orphans: [highOrphan, lowOrphan])
        let vm = ScanViewModel(scanner: mockScanner, orphanDetector: mockOrphanDetector)

        vm.startScan()
        await TestSupport.awaitCondition { vm.state == .results }

        let leftovers = vm.scanResult?.categories.first { $0.name == "App Leftovers" }
        #expect(leftovers != nil)
        #expect(leftovers?.items.count == 2)

        let highItem = leftovers?.items.first { $0.name.contains("HighApp") }
        let lowItem = leftovers?.items.first { $0.name.contains("LowApp") }
        #expect(highItem?.confidence == .high)
        #expect(lowItem?.confidence == .low)
    }

    @Test @MainActor func noLeftoversCategoryWhenNoOrphans() async {
        let mockScanner = MockScanner {
            AsyncStream { continuation in
                let result = ScanResult(
                    categories: [
                        CleanCategory(
                            name: "System Caches", icon: "internaldrive", description: "",
                            items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/cache"), size: 1000)]
                        ),
                    ],
                    orphanedApps: [],
                    scanDuration: 0.1,
                    scanDate: Date()
                )
                continuation.yield(.complete(result))
                continuation.finish()
            }
        }

        let mockOrphanDetector = MockOrphanDetector(orphans: [])
        let vm = ScanViewModel(scanner: mockScanner, orphanDetector: mockOrphanDetector)

        vm.startScan()
        await TestSupport.awaitCondition { vm.state == .results }

        #expect(vm.scanResult?.categories.count == 1)
        #expect(vm.scanResult?.categories.first { $0.name == "App Leftovers" } == nil)
    }
}
