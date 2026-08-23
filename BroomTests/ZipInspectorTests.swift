import Foundation
import Testing
@testable import Broom

@Suite("ZipInspector")
struct ZipInspectorTests {
    @Test func readsEntryNamesFromRealZip() throws {
        let root = try TestSupport.makeTempDirectory()
        let payload = root.appendingPathComponent("MyApp.app/Contents/MacOS/MyApp")
        try TestSupport.writeFile(at: payload)
        let zipURL = root.appendingPathComponent("archive.zip")
        try runZip(args: ["-qr", zipURL.lastPathComponent, "MyApp.app"], cwd: root)

        let names = ZipInspector.firstEntryNames(at: zipURL)
        #expect(names != nil)
        #expect(names?.isEmpty == false)
    }

    @Test func installerPayloadZipQualifies() throws {
        let root = try TestSupport.makeTempDirectory()
        try TestSupport.writeFile(at: root.appendingPathComponent("Tool.app/Contents/MacOS/Tool"))
        let zipURL = root.appendingPathComponent("tool.zip")
        try runZip(args: ["-qr", zipURL.lastPathComponent, "Tool.app"], cwd: root)

        #expect(ZipInspector.looksLikeInstallerArchive(at: zipURL) == true)
    }

    @Test func plainContentZipDoesNotQualify() throws {
        let root = try TestSupport.makeTempDirectory()
        try TestSupport.writeFile(at: root.appendingPathComponent("photos/beach.jpg"))
        try TestSupport.writeFile(at: root.appendingPathComponent("docs/readme.md"))
        let zipURL = root.appendingPathComponent("photos.zip")
        try runZip(args: ["-qr", zipURL.lastPathComponent, "photos", "docs"], cwd: root)

        #expect(ZipInspector.looksLikeInstallerArchive(at: zipURL) == false)
    }

    @Test func nonZipFileReturnsNil() throws {
        let root = try TestSupport.makeTempDirectory()
        let notAZip = root.appendingPathComponent("notazip.zip")
        try Data("definitely not a zip".utf8).write(to: notAZip)

        #expect(ZipInspector.firstEntryNames(at: notAZip) == nil)
        #expect(ZipInspector.looksLikeInstallerArchive(at: notAZip) == false)
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
        #expect(process.terminationStatus == 0)
    }
}
