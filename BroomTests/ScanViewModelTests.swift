import Foundation
import Testing
@testable import Broom

@Suite("ScanViewModel")
struct ScanViewModelTests {
    @MainActor
    @Test func mergesOrphansIntoScanResults() async {
        let scanner = MockScanner {
            AsyncStream { continuation in
                continuation.yield(.complete(ScanResult(
                    categories: [
                        CleanCategory(
                            name: "Caches",
                            icon: "folder",
                            description: "",
                            items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/cache"), size: 100)]
                        ),
                    ],
                    orphanedApps: [],
                    scanDuration: 0.1,
                    scanDate: Date()
                )))
                continuation.finish()
            }
        }

        let orphans = [
            OrphanedApp(
                appName: "OldApp",
                confidence: .medium,
                locations: [CleanableItem(path: URL(fileURLWithPath: "/tmp/orphan"), size: 50, isSelected: false)]
            ),
        ]

        let viewModel = ScanViewModel(
            scanner: scanner,
            cleaner: MockCleaner(),
            orphanDetector: MockOrphanDetector(orphans: orphans),
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults)
            }
        )

        viewModel.startScan()
        await TestSupport.awaitCondition { viewModel.state == .results }

        #expect(viewModel.scanResult?.orphanedApps.count == 1)
        #expect(viewModel.scanResult?.totalSize == 150)
    }

    @MainActor
    @Test func confirmCleanUsesDeletePreference() async {
        let cleaner = MockCleaner(
            report: CleanReport(freedBytes: 120, itemsCleaned: 1, itemsFailed: 0, errors: [], duration: 0.1)
        )
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "moveToTrash")

        let viewModel = ScanViewModel(
            scanner: MockScanner {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            cleaner: cleaner,
            orphanDetector: MockOrphanDetector(orphans: []),
            preferencesProvider: { AppPreferences(userDefaults: defaults) }
        )
        viewModel.scanResult = ScanResult(
            categories: [
                CleanCategory(
                    name: "Caches",
                    icon: "folder",
                    description: "",
                    items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/cache"), size: 120)]
                ),
            ],
            orphanedApps: [],
            scanDuration: 0.1,
            scanDate: Date()
        )

        viewModel.startClean()
        #expect(viewModel.showCleanConfirmation == true)

        viewModel.confirmClean()
        await TestSupport.awaitCondition {
            if case .done = viewModel.state { return true }
            return false
        }

        #expect(cleaner.lastMoveToTrash == false)
        #expect(cleaner.lastItems.count == 1)
    }

    @MainActor
    @Test func doneStateCarriesMovedToTrashTrue() async {
        let cleaner = MockCleaner(
            report: CleanReport(freedBytes: 100, itemsCleaned: 1, itemsFailed: 0, errors: [], duration: 0.1)
        )
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(true, forKey: "moveToTrash")

        let viewModel = ScanViewModel(
            scanner: MockScanner { AsyncStream { $0.finish() } },
            cleaner: cleaner,
            orphanDetector: MockOrphanDetector(orphans: []),
            preferencesProvider: { AppPreferences(userDefaults: defaults) }
        )
        viewModel.scanResult = ScanResult(
            categories: [
                CleanCategory(name: "Test", icon: "folder", description: "", items: [
                    CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100),
                ]),
            ],
            orphanedApps: [],
            scanDuration: 0.1,
            scanDate: Date()
        )

        viewModel.startClean()
        viewModel.confirmClean()
        await TestSupport.awaitCondition {
            if case .done = viewModel.state { return true }
            return false
        }

        if case .done(_, _, _, let movedToTrash) = viewModel.state {
            #expect(movedToTrash == true)
        } else {
            Issue.record("Expected done state")
        }
    }

    @MainActor
    @Test func doneStateCarriesMovedToTrashFalse() async {
        let cleaner = MockCleaner(
            report: CleanReport(freedBytes: 100, itemsCleaned: 1, itemsFailed: 0, errors: [], duration: 0.1)
        )
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "moveToTrash")

        let viewModel = ScanViewModel(
            scanner: MockScanner { AsyncStream { $0.finish() } },
            cleaner: cleaner,
            orphanDetector: MockOrphanDetector(orphans: []),
            preferencesProvider: { AppPreferences(userDefaults: defaults) }
        )
        viewModel.scanResult = ScanResult(
            categories: [
                CleanCategory(name: "Test", icon: "folder", description: "", items: [
                    CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100),
                ]),
            ],
            orphanedApps: [],
            scanDuration: 0.1,
            scanDate: Date()
        )

        viewModel.startClean()
        viewModel.confirmClean()
        await TestSupport.awaitCondition {
            if case .done = viewModel.state { return true }
            return false
        }

        if case .done(_, _, _, let movedToTrash) = viewModel.state {
            #expect(movedToTrash == false)
        } else {
            Issue.record("Expected done state")
        }
    }
}
