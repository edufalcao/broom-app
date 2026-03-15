import Foundation
import Testing
@testable import Broom

@Suite("FileScanner")
struct FileScannerTests {
    @Test func skipsDeveloperCachesWhenDisabled() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: locations.xcodeDerivedData.appendingPathComponent("build.dat"))
        try TestSupport.writeFile(at: locations.spmCache.appendingPathComponent("package.dat"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: {
                AppPreferences(
                    userDefaults: {
                        let defaults = UserDefaults(suiteName: UUID().uuidString)!
                        defaults.set(false, forKey: "showDeveloperCaches")
                        return defaults
                    }()
                )
            }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        #expect(result?.categories.contains(where: { $0.name == "Xcode Data" }) == false)
        #expect(result?.categories.contains(where: { $0.name == "Developer Caches" }) == false)
    }

    @Test func skipsDSStoreCategoryWhenDisabled() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: root.appendingPathComponent("Desktop/.DS_Store"))

        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "scanDSStores")
        let preferences = AppPreferences(userDefaults: defaults)
        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { preferences }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        #expect(result?.categories.contains(where: { $0.name == ".DS_Store Files" }) == false)
    }

    @Test func appliesSafeListEntriesToScannedDirectories() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        let caches = locations.userCaches.appendingPathComponent("com.example.cache")
        try TestSupport.writeFile(at: caches.appendingPathComponent("cached.dat"))

        let safeListURL = root.appendingPathComponent("safelist.json")
        let data = try JSONEncoder().encode([caches.path])
        try data.write(to: safeListURL)

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: {
                let defaults = UserDefaults(suiteName: UUID().uuidString)!
                return AppPreferences(userDefaults: defaults, safeListURL: safeListURL)
            }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let systemCaches = result?.categories.first(where: { $0.name == "System Caches" })
        #expect(systemCaches?.items.isEmpty == true)
    }

    @Test func respectsMinimumTempFileAge() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        let oldFile = locations.userTmpDir.appendingPathComponent("old.tmp")
        let newFile = locations.userTmpDir.appendingPathComponent("new.tmp")
        try TestSupport.writeFile(at: oldFile)
        try TestSupport.writeFile(at: newFile)

        let oldDate = Date().addingTimeInterval(-26 * 3600)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: oldFile.path)

        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(24, forKey: "minTempFileAgeHours")
        let preferences = AppPreferences(userDefaults: defaults)
        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { preferences }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let tempCategory = result?.categories.first(where: { $0.name == "Temporary Files" })
        #expect(tempCategory?.items.count == 1)
        #expect(tempCategory?.items.first?.path.lastPathComponent == "old.tmp")
    }

    private func makeLocations(root: URL) throws -> FileScannerLocations {
        let library = root.appendingPathComponent("Library")
        let caches = library.appendingPathComponent("Caches")
        let chromeBase = caches.appendingPathComponent("Google/Chrome")
        let braveBase = caches.appendingPathComponent("BraveSoftware/Brave-Browser")
        let edgeBase = caches.appendingPathComponent("com.microsoft.edgemac")
        let tmp = root.appendingPathComponent("tmp")

        for directory in [library, caches, chromeBase, braveBase, edgeBase, tmp] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return FileScannerLocations(
            home: root,
            userCaches: caches,
            chromeCacheBase: chromeBase,
            firefoxCache: caches.appendingPathComponent("org.mozilla.firefox"),
            safariCache: caches.appendingPathComponent("com.apple.Safari"),
            arcCache: caches.appendingPathComponent("company.thebrowser.Browser"),
            braveCacheBase: braveBase,
            edgeCacheBase: edgeBase,
            userLogs: library.appendingPathComponent("Logs"),
            systemLogs: root.appendingPathComponent("SystemLogs"),
            diagnosticReports: library.appendingPathComponent("Logs/DiagnosticReports"),
            userTmpDir: tmp,
            systemTmp: root.appendingPathComponent("SystemTmp"),
            xcodeDerivedData: library.appendingPathComponent("Developer/Xcode/DerivedData"),
            xcodeArchives: library.appendingPathComponent("Developer/Xcode/Archives"),
            spmCache: caches.appendingPathComponent("org.swift.swiftpm"),
            cocoapodsCache: caches.appendingPathComponent("CocoaPods"),
            homebrewCache: caches.appendingPathComponent("Homebrew"),
            npmCache: root.appendingPathComponent(".npm/_cacache"),
            yarnCache: caches.appendingPathComponent("Yarn"),
            pipCache: caches.appendingPathComponent("pip"),
            mailAttachments: library.appendingPathComponent("Containers/com.apple.mail/Data/Library/Mail Downloads")
        )
    }
}
