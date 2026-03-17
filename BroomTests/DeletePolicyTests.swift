import Foundation
import Testing
@testable import Broom

@Suite("DeletePolicy")
struct DeletePolicyTests {

    // MARK: - Path validation

    @Test func blocksRelativePaths() {
        let url = URL(string: "relative/path/file.txt")!
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.pathNotAbsolute) = result else {
            Issue.record("Expected pathNotAbsolute, got \(result)")
            return
        }
    }

    @Test func blocksMissingPaths() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString)/file.txt")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.missingPath) = result else {
            Issue.record("Expected missingPath, got \(result)")
            return
        }
    }

    // MARK: - Protected system paths

    @Test func blocksSystemLibraryInGenericClean() {
        let url = URL(fileURLWithPath: "/System/Library/Frameworks/AppKit.framework")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func blocksSystemLibraryInExplicitUninstall() {
        let url = URL(fileURLWithPath: "/System/Library/Frameworks/AppKit.framework")
        let result = DeletePolicy.validate(path: url, context: .explicitUninstall)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func blocksUsrBin() {
        let url = URL(fileURLWithPath: "/usr/bin/ls")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func blocksSbin() {
        let url = URL(fileURLWithPath: "/sbin/mount")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func blocksBin() {
        let url = URL(fileURLWithPath: "/bin/sh")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func blocksLibraryApple() {
        let url = URL(fileURLWithPath: "/Library/Apple/System/Library/something")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    // MARK: - /var/db/receipts context behavior

    @Test func blocksVarDbReceiptsInGenericClean() {
        let url = URL(fileURLWithPath: "/private/var/db/receipts/com.example.pkg.plist")
        let result = DeletePolicy.validate(path: url, context: .genericClean)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    @Test func allowsVarDbReceiptsInExplicitUninstall() throws {
        let dir = URL(fileURLWithPath: "/private/var/db/receipts")
        guard FileManager.default.fileExists(atPath: dir.path) else {
            return // Skip on systems without receipts directory
        }

        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        guard let firstReceipt = contents.first else {
            return // Skip if no receipts exist
        }

        let result = DeletePolicy.validate(path: firstReceipt, context: .explicitUninstall)
        switch result {
        case .allowed:
            break // expected
        case .blocked(.permissionDenied):
            break // acceptable — the file exists but we lack write access
        case .blocked(let reason):
            Issue.record("Expected allowed or permissionDenied for receipt in explicitUninstall, got blocked(\(reason))")
        }
    }

    @Test func blocksVarDbNonReceiptsInExplicitUninstall() {
        let url = URL(fileURLWithPath: "/private/var/db/something-else")
        let result = DeletePolicy.validate(path: url, context: .explicitUninstall)
        guard case .blocked(.protectedSystemPath) = result else {
            Issue.record("Expected protectedSystemPath, got \(result)")
            return
        }
    }

    // MARK: - Symlink safety

    @Test func blocksSymlinksToProtectedLocations() throws {
        let dir = try TestSupport.makeTempDirectory()
        let symlinkPath = dir.appendingPathComponent("dangerous-link")
        try FileManager.default.createSymbolicLink(
            atPath: symlinkPath.path,
            withDestinationPath: "/System/Library/Frameworks"
        )

        let result = DeletePolicy.validate(path: symlinkPath, context: .genericClean)
        guard case .blocked(.unsafeSymlink) = result else {
            Issue.record("Expected unsafeSymlink, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    @Test func allowsSafeSymlinks() throws {
        let dir = try TestSupport.makeTempDirectory()
        let targetFile = dir.appendingPathComponent("target.txt")
        try TestSupport.writeFile(at: targetFile)
        let symlinkPath = dir.appendingPathComponent("safe-link")
        try FileManager.default.createSymbolicLink(
            atPath: symlinkPath.path,
            withDestinationPath: targetFile.path
        )

        let result = DeletePolicy.validate(path: symlinkPath, context: .genericClean)
        guard case .allowed = result else {
            Issue.record("Expected allowed, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    // MARK: - Protected data families

    @Test func blocksProtectedDataFamilyInGenericClean() throws {
        let dir = try TestSupport.makeTempDirectory()
        let protectedPath = dir.appendingPathComponent("1password")
        try FileManager.default.createDirectory(at: protectedPath, withIntermediateDirectories: true)

        let result = DeletePolicy.validate(path: protectedPath, context: .genericClean)
        guard case .blocked(.protectedDataFamily) = result else {
            Issue.record("Expected protectedDataFamily, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    @Test func allowsProtectedDataFamilyInExplicitUninstall() throws {
        let dir = try TestSupport.makeTempDirectory()
        let protectedPath = dir.appendingPathComponent("1password")
        try FileManager.default.createDirectory(at: protectedPath, withIntermediateDirectories: true)

        let result = DeletePolicy.validate(path: protectedPath, context: .explicitUninstall)
        guard case .allowed = result else {
            Issue.record("Expected allowed in explicitUninstall, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    @Test func blocksProtectedBundleIDPathInGenericClean() throws {
        let dir = try TestSupport.makeTempDirectory()
        let protectedPath = dir.appendingPathComponent("com.agilebits.onepassword7")
        try FileManager.default.createDirectory(at: protectedPath, withIntermediateDirectories: true)

        let result = DeletePolicy.validate(path: protectedPath, context: .genericClean)
        guard case .blocked(.protectedDataFamily) = result else {
            Issue.record("Expected protectedDataFamily, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    // MARK: - Valid paths

    @Test func allowsValidUserLibraryPath() throws {
        let dir = try TestSupport.makeTempDirectory()
        let file = dir.appendingPathComponent("com.example.app.plist")
        try TestSupport.writeFile(at: file)

        let result = DeletePolicy.validate(path: file, context: .genericClean)
        guard case .allowed = result else {
            Issue.record("Expected allowed, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    @Test func allowsRegularFileInExplicitUninstall() throws {
        let dir = try TestSupport.makeTempDirectory()
        let file = dir.appendingPathComponent("cache.dat")
        try TestSupport.writeFile(at: file)

        let result = DeletePolicy.validate(path: file, context: .explicitUninstall)
        guard case .allowed = result else {
            Issue.record("Expected allowed, got \(result)")
            return
        }

        try FileManager.default.removeItem(at: dir)
    }

    // MARK: - DeleteContext enum values

    @Test func deleteContextHasBothCases() {
        let generic = DeleteContext.genericClean
        let explicit = DeleteContext.explicitUninstall
        #expect(generic != explicit)
    }

    // MARK: - DeleteBlockReason raw values

    @Test func blockReasonRawValues() {
        #expect(DeleteBlockReason.protectedSystemPath.rawValue == "protectedSystemPath")
        #expect(DeleteBlockReason.protectedDataFamily.rawValue == "protectedDataFamily")
        #expect(DeleteBlockReason.unsafeSymlink.rawValue == "unsafeSymlink")
        #expect(DeleteBlockReason.missingPath.rawValue == "missingPath")
        #expect(DeleteBlockReason.permissionDenied.rawValue == "permissionDenied")
        #expect(DeleteBlockReason.pathNotAbsolute.rawValue == "pathNotAbsolute")
    }
}
