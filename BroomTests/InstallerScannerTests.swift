import Foundation
import Testing
@testable import Broom

@Suite("InstallerScanner")
struct InstallerScannerTests {
    @Test func findsOldInstallerFilesInSources() async throws {
        var fixture = try makeFixture()
        let oldDate = Date().addingTimeInterval(-14 * 86_400)
        let dmg = fixture.root.appendingPathComponent("Downloads/Installer.dmg")
        try TestSupport.writeFile(at: dmg)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: dmg.path)

        let files = try await scan(fixture)

        #expect(files.count == 1)
        #expect(Self.normalize(files.first?.path) == Self.normalize(dmg))
    }

    @Test func skipsFilesYoungerThanAgeGate() async throws {
        var fixture = try makeFixture()
        let fresh = fixture.root.appendingPathComponent("Downloads/JustDownloaded.dmg")
        try TestSupport.writeFile(at: fresh)

        let files = try await scan(fixture)

        #expect(files.isEmpty)
    }

    @Test func skipsMountedDiskImagesEvenWhenOld() async throws {
        var fixture = try makeFixture()
        let oldDate = Date().addingTimeInterval(-14 * 86_400)
        let mounted = fixture.root.appendingPathComponent("Downloads/Mounted.dmg")
        try TestSupport.writeFile(at: mounted)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: mounted.path)

        fixture.mountedPaths = [Self.normalize(mounted)]
        let files = try await scan(fixture)

        #expect(files.isEmpty)
    }

    @Test func plainZipDoesNotQualifyButAppZipDoes() async throws {
        var fixture = try makeFixture()
        let oldDate = Date().addingTimeInterval(-14 * 86_400)

        let appDir = fixture.root.appendingPathComponent("Downloads/AppBundle.app")
        try TestSupport.writeFile(at: appDir.appendingPathComponent("Contents/MacOS/Bin"))
        let appZip = fixture.root.appendingPathComponent("Downloads/app.zip")
        try runZip(args: ["-qr", "app.zip", "AppBundle.app"], cwd: fixture.root.appendingPathComponent("Downloads"))

        let photo = fixture.root.appendingPathComponent("Downloads/photo.jpg")
        try TestSupport.writeFile(at: photo)
        let photosZip = fixture.root.appendingPathComponent("Downloads/photos.zip")
        try runZip(args: ["-qr", "photos.zip", "photo.jpg"], cwd: fixture.root.appendingPathComponent("Downloads"))

        for url in [appZip, appDir, photo, photosZip] {
            try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: url.path)
        }

        let files = try await scan(fixture)

        // The .app directory itself is not an installer file type; only the zip qualifies.
        #expect(files.count == 1)
        #expect(Self.normalize(files.first?.path) == Self.normalize(appZip))
    }

    @Test func scansOneSubdirectoryDeep() async throws {
        var fixture = try makeFixture()
        let oldDate = Date().addingTimeInterval(-14 * 86_400)
        let nested = fixture.root.appendingPathComponent("Downloads/Telegram Desktop/setup.pkg")
        try TestSupport.writeFile(at: nested)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: nested.path)

        let tooDeep = fixture.root.appendingPathComponent("Downloads/a/b/deep.dmg")
        try TestSupport.writeFile(at: tooDeep)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: tooDeep.path)

        let files = try await scan(fixture)

        #expect(files.count == 1)
        #expect(Self.normalize(files.first?.path) == Self.normalize(nested))
    }

    @Test func homebrewDownloadsAreScanned() async throws {
        var fixture = try makeFixture()
        let oldDate = Date().addingTimeInterval(-14 * 86_400)
        let caskDmg = fixture.homebrewDownloads.appendingPathComponent("firefox-100.dmg")
        try TestSupport.writeFile(at: caskDmg)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: caskDmg.path)

        let files = try await scan(fixture)

        #expect(files.count == 1)
    }


    /// macOS temp dirs live behind a /var -> /private/var symlink; compare
    /// paths with that prefix normalized away.
    private static func normalize(_ url: URL?) -> String {
        guard let url else { return "" }
        return url.path.replacingOccurrences(of: "/private/", with: "/")
    }

    // MARK: - Fixtures

    private struct Fixture {
        let root: URL
        let homebrewDownloads: URL
        var mountedPaths: Set<String> = []
    }

    private func makeFixture() throws -> Fixture {
        let root = try TestSupport.makeTempDirectory()
        let homebrewDownloads = root.appendingPathComponent("Homebrew/downloads")
        for dir in [
            root.appendingPathComponent("Downloads"),
            root.appendingPathComponent("Desktop"),
            root.appendingPathComponent("Documents"),
            homebrewDownloads,
        ] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return Fixture(root: root, homebrewDownloads: homebrewDownloads)
    }

    private func scan(_ fixture: Fixture) async throws -> [LargeFile] {
        let scanner = InstallerScanner(
            locations: InstallerScanLocations(
                sources: [
                    fixture.root.appendingPathComponent("Downloads"),
                    fixture.root.appendingPathComponent("Desktop"),
                    fixture.root.appendingPathComponent("Documents"),
                ],
                homebrewDownloads: fixture.homebrewDownloads
            ),
            minAgeDaysProvider: { 7 },
            mountedPathsProvider: { fixture.mountedPaths }
        )

        var result: [LargeFile] = []
        for await progress in scanner.scan() {
            if case .complete(let files) = progress {
                result = files
            }
        }
        return result
    }

    private func runZip(args: [String], cwd: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = args
        process.currentDirectoryURL = cwd
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
    }
}
