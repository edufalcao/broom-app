import Foundation
import Testing
@testable import Broom

@Suite("Docker and Homebrew Scan")
struct DockerHomebrewScanTests {
    @Test func dockerScanReturnsNilWhenNotInstalled() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "DockerScanTest")
        defer { try? FileManager.default.removeItem(at: dir) }

        let scanner = FileScanner(locations: makeLocations(root: dir))
        let result = await scanner.scanDocker(userEntries: [])
        #expect(result == nil)
    }

    @Test func homebrewScanReturnsNilWhenNotInstalled() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "HomebrewScanTest")
        defer { try? FileManager.default.removeItem(at: dir) }

        let scanner = FileScanner(locations: makeLocations(root: dir))
        let result = await scanner.scanHomebrewExtended(userEntries: [])
        #expect(result == nil)
    }

    @Test func homebrewCategoryDefaultsToUnselected() {
        let category = CleanCategory(
            name: "Homebrew",
            icon: "mug",
            description: "Test",
            items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100, isSelected: false)],
            defaultSelected: false
        )

        #expect(category.isSelected == false)
        #expect(category.items[0].isSelected == false)
    }

    private func makeLocations(root: URL) -> FileScannerLocations {
        let library = root.appendingPathComponent("Library")
        let caches = library.appendingPathComponent("Caches")

        return FileScannerLocations(
            home: root,
            userCaches: caches,
            downloads: root.appendingPathComponent("Downloads"),
            chromeCacheBase: caches.appendingPathComponent("Google/Chrome"),
            firefoxCache: caches.appendingPathComponent("org.mozilla.firefox"),
            safariCache: caches.appendingPathComponent("com.apple.Safari"),
            arcCache: caches.appendingPathComponent("company.thebrowser.Browser"),
            braveCacheBase: caches.appendingPathComponent("BraveSoftware/Brave-Browser"),
            edgeCacheBase: caches.appendingPathComponent("com.microsoft.edgemac"),
            userLogs: library.appendingPathComponent("Logs"),
            systemLogs: root.appendingPathComponent("SystemLogs"),
            diagnosticReports: library.appendingPathComponent("Logs/DiagnosticReports"),
            userTmpDir: root.appendingPathComponent("tmp"),
            systemTmp: root.appendingPathComponent("SystemTmp"),
            xcodeDerivedData: library.appendingPathComponent("Developer/Xcode/DerivedData"),
            xcodeArchives: library.appendingPathComponent("Developer/Xcode/Archives"),
            spmCache: caches.appendingPathComponent("org.swift.swiftpm"),
            cocoapodsCache: caches.appendingPathComponent("CocoaPods"),
            homebrewCache: caches.appendingPathComponent("Homebrew"),
            homebrewCellar: root.appendingPathComponent("Homebrew/Cellar"),
            npmCache: root.appendingPathComponent(".npm/_cacache"),
            yarnCache: caches.appendingPathComponent("Yarn"),
            pipCache: caches.appendingPathComponent("pip"),
            dockerData: library.appendingPathComponent("Containers/com.docker.docker/Data/vms"),
            dockerConfig: root.appendingPathComponent(".docker"),
            mailAttachments: library.appendingPathComponent("Containers/com.apple.mail/Data/Library/Mail Downloads")
        )
    }
}
