import Foundation
import Testing
@testable import Broom

@Suite("Cleaner Enrichment")
struct CleanerEnrichmentTests {
    @Test func chromiumGPUCacheIsOfferedPerProfile() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        let gpuCache = locations.chromeCacheBase
            .appendingPathComponent("Default/GPUCache")
        try TestSupport.writeFile(at: gpuCache.appendingPathComponent("shader.bin"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let browserCaches = result?.categories.first(where: { $0.name == "Browser Caches" })
        #expect(browserCaches?.items.contains(where: { $0.name == "Chrome — GPUCache" }) == true)
    }

    @Test func extendedBrowsersAreScanned() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: locations.vivaldiCache.appendingPathComponent("data"))
        try TestSupport.writeFile(at: locations.thunderbirdCache.appendingPathComponent("data"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let browserCaches = result?.categories.first(where: { $0.name == "Browser Caches" })
        #expect(browserCaches?.items.contains(where: { $0.name == "Vivaldi" }) == true)
        #expect(browserCaches?.items.contains(where: { $0.name == "Thunderbird" }) == true)
    }

    @Test func appleSystemDataAppearsInSystemCaches() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(
            at: locations.savedApplicationState.appendingPathComponent("com.example.state")
        )
        try TestSupport.writeFile(
            at: locations.messagesStickerCache.appendingPathComponent("sticker.dat")
        )

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let systemCaches = result?.categories.first(where: { $0.name == "System Caches" })
        #expect(systemCaches?.items.contains(where: { $0.name == "Saved Application State" }) == true)
        #expect(systemCaches?.items.contains(where: { $0.name == "Messages Sticker Cache" }) == true)
    }

    @Test func extendedDeveloperCachesAreScanned() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: locations.cargoRegistryCache.appendingPathComponent("crate.crate"))
        try TestSupport.writeFile(at: locations.bunInstallCache.appendingPathComponent("pkg.tgz"))
        try TestSupport.writeFile(at: locations.corepackCacheCandidates[0].appendingPathComponent("pnpm"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let developerCaches = result?.categories.first(where: { $0.name == "Developer Caches" })
        #expect(developerCaches?.items.contains(where: { $0.name == "Cargo Registry" }) == true)
        #expect(developerCaches?.items.contains(where: { $0.name == "Bun" }) == true)
        #expect(developerCaches?.items.contains(where: { $0.name == "Corepack" }) == true)
    }

    @Test func simulatorDataSkippedWhileXcodeIsRunning() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: locations.simulatorCaches.appendingPathComponent("cache.bin"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) },
            runningBundleIDsProvider: { ["com.apple.dt.Xcode"] }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        #expect(result?.categories.contains(where: { $0.name == "Simulator Data" }) == false)
    }

    @Test func simulatorDataOfferedWhenToolsNotRunning() async throws {
        let root = try TestSupport.makeTempDirectory()
        let locations = try makeLocations(root: root)
        try TestSupport.writeFile(at: locations.simulatorLogs.appendingPathComponent("sim.log"))
        let deviceTmp = locations.simulatorDevices
            .appendingPathComponent("AAAAAAAA-1111-2222-3333-444444444444")
            .appendingPathComponent("data/tmp")
        try TestSupport.writeFile(at: deviceTmp.appendingPathComponent("scratch.dat"))

        let scanner = FileScanner(
            locations: locations,
            preferencesProvider: { AppPreferences(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) },
            runningBundleIDsProvider: { [] }
        )

        let result = await TestSupport.collectScanResult(from: scanner)
        let simulatorData = result?.categories.first(where: { $0.name == "Simulator Data" })
        #expect(simulatorData != nil)
        #expect(simulatorData?.items.contains(where: { $0.name == "Simulator Logs" }) == true)
        #expect(simulatorData?.items.contains(where: { $0.name.hasPrefix("Simulator Temp (AAAAAAAA)") }) == true)
    }

    private func makeLocations(root: URL) throws -> FileScannerLocations {
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
            mailAttachments: library.appendingPathComponent("Containers/com.apple.mail/Data/Library/Mail Downloads"),
            vivaldiCache: caches.appendingPathComponent("com.vivaldi.Vivaldi"),
            operaCache: caches.appendingPathComponent("com.operasoftware.Opera"),
            yandexCacheBase: caches.appendingPathComponent("Yandex/YandexBrowser"),
            orionCache: caches.appendingPathComponent("com.kagi.kagimacOS"),
            zenCache: caches.appendingPathComponent("zen"),
            cometCache: caches.appendingPathComponent("Comet"),
            heliumCache: caches.appendingPathComponent("net.imput.helium"),
            qqBrowserCache: caches.appendingPathComponent("com.tencent.QQBrowser3"),
            thunderbirdCache: caches.appendingPathComponent("org.mozilla.thunderbird"),
            diaCacheBase: caches.appendingPathComponent("Dia/User Data"),
            savedApplicationState: library.appendingPathComponent("Saved Application State"),
            messagesStickerCache: root.appendingPathComponent("Messages/StickerCache"),
            messagesPreviewStickerCache: root.appendingPathComponent("Messages/Caches/Previews/StickerCache"),
            cargoRegistryCache: root.appendingPathComponent(".cargo/registry/cache"),
            bunInstallCache: root.appendingPathComponent(".bun/install/cache"),
            corepackCacheCandidates: [
                root.appendingPathComponent(".cache/node/corepack"),
                caches.appendingPathComponent("node/corepack"),
            ],
            rbenvCache: root.appendingPathComponent(".rbenv/cache"),
            gemSpecsCache: root.appendingPathComponent(".gem/specs"),
            bundlerCache: root.appendingPathComponent(".bundle/cache"),
            simulatorCaches: library.appendingPathComponent("Developer/CoreSimulator/Caches"),
            simulatorDevices: library.appendingPathComponent("Developer/CoreSimulator/Devices"),
            simulatorLogs: library.appendingPathComponent("Logs/CoreSimulator")
        )
    }
}
