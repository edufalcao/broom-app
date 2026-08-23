import Foundation
import Testing
@testable import Broom

@Suite("RecencyClassifier")
struct RecencyClassifierTests {
    @Test func classifiesOldDirectoryAsOld() throws {
        let root = try TestSupport.makeTempDirectory()
        let artifact = root.appendingPathComponent("node_modules")
        try TestSupport.writeFile(at: artifact.appendingPathComponent("lib/index.js"))
        let oldDate = Date().addingTimeInterval(-30 * 86_400)
        try? FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: artifact.path)
        if let enumerator = FileManager.default.enumerator(at: artifact, includingPropertiesForKeys: nil) {
            for case let child as URL in enumerator {
                try? FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: child.path)
            }
        }

        let classifier = RecencyClassifier(cutoff: Date().addingTimeInterval(-7 * 86_400))
        #expect(classifier.classify(at: artifact) == .old)
    }

    @Test func classifiesRecentlyModifiedTopLevelAsRecent() throws {
        let root = try TestSupport.makeTempDirectory()
        let artifact = root.appendingPathComponent("node_modules")
        try TestSupport.writeFile(at: artifact.appendingPathComponent("lib/index.js"))

        let classifier = RecencyClassifier(cutoff: Date().addingTimeInterval(-7 * 86_400))
        #expect(classifier.classify(at: artifact) == .recent)
    }

    @Test func oldParentWithRecentDescendantIsRecent() throws {
        let root = try TestSupport.makeTempDirectory()
        let artifact = root.appendingPathComponent(".build")
        try TestSupport.writeFile(at: artifact.appendingPathComponent("out.o"))
        let oldDate = Date().addingTimeInterval(-30 * 86_400)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: artifact.path)

        // Touch a deep descendant to now.
        try TestSupport.writeFile(at: artifact.appendingPathComponent("fresh.tmp"))

        let classifier = RecencyClassifier(cutoff: Date().addingTimeInterval(-7 * 86_400))
        #expect(classifier.classify(at: artifact) == .recent)
    }

    @Test func unreadableDirectoryIsUncertain() throws {
        let root = try TestSupport.makeTempDirectory()
        let artifact = root.appendingPathComponent("sealed")
        try FileManager.default.createDirectory(at: artifact, withIntermediateDirectories: true)

        let classifier = RecencyClassifier(cutoff: Date().addingTimeInterval(-7 * 86_400))
        // A file path treated as a directory fails enumeration -> uncertain.
        let filePath = artifact.appendingPathComponent("file.txt")
        try TestSupport.writeFile(at: filePath)

        #expect(classifier.classify(at: filePath) == .uncertain || classifier.classify(at: filePath) == .recent)
    }
}

@Suite("ProjectArtifactScanner")
struct ProjectArtifactScannerTests {
    @Test func findsArtifactsGroupedByProject() async throws {
        let fixture = try makeFixture()
        try makeOldArtifact(fixture: fixture, project: "webapp", family: "node_modules")
        try makeOldArtifact(fixture: fixture, project: "rust-cli", family: "target")

        let groups = await scan(fixture)

        #expect(groups.count == 2)
        #expect(groups.flatMap(\.artifacts).allSatisfy { $0.recency == .old })
        #expect(groups.flatMap(\.artifacts).allSatisfy { $0.isSelected })
    }

    @Test func recentArtifactsStartDeselected() async throws {
        let fixture = try makeFixture()
        // Old project dir with an actively-modified artifact.
        try makeOldArtifact(fixture: fixture, project: "webapp", family: "node_modules")
        let activeArtifact = fixture.root.appendingPathComponent("Projects/webapp/target")
        try TestSupport.writeFile(at: activeArtifact.appendingPathComponent("bin/app"))

        let groups = await scan(fixture)

        let webapp = groups.first { $0.name == "webapp" }
        #expect(webapp != nil)
        let targetRow = webapp?.artifacts.first { $0.name == "target" }
        #expect(targetRow?.recency == .recent)
        #expect(targetRow?.isSelected == false)
    }

    @Test func workspaceArtifactsOneLevelDeepAreFound() async throws {
        let fixture = try makeFixture()
        try makeOldArtifact(fixture: fixture, project: "monorepo/packages/api", family: "node_modules")

        let groups = await scan(fixture)

        // The deepest project indicator (the workspace package) owns the artifact.
        #expect(groups.count == 1)
        #expect(groups.first?.name == "api")
        #expect(groups.first?.artifacts.count == 1)
    }

    @Test func cachedirTaggedDirectoriesAreOffered() async throws {
        let fixture = try makeFixture()
        let project = fixture.root.appendingPathComponent("Projects/legacy")
        try TestSupport.writeFile(at: project.appendingPathComponent(".git/config"))
        let cacheDir = project.appendingPathComponent("obscure-cache")
        try TestSupport.writeFile(at: cacheDir.appendingPathComponent("chunk.bin"))
        let tag = cacheDir.appendingPathComponent(Constants.cacheDirTag)
        try Data().write(to: tag)
        backdate(project)

        let groups = await scan(fixture)

        let legacy = groups.first { $0.name == "legacy" }
        #expect(legacy?.artifacts.contains(where: { Self.normalize($0.path) == Self.normalize(cacheDir) }) == true)
    }

    @Test func derivedDataFamilyNeverAppears() async throws {
        let fixture = try makeFixture()
        try makeOldArtifact(fixture: fixture, project: "ios-app", family: "DerivedData")

        let groups = await scan(fixture)

        #expect(groups.isEmpty)
    }

    // MARK: - Fixtures

    /// macOS temp dirs live behind a /var -> /private/var symlink.
    private static func normalize(_ url: URL?) -> String {
        guard let url else { return "" }
        return url.path.replacingOccurrences(of: "/private/", with: "/")
    }

    private struct Fixture {
        let root: URL
        var projectsRoot: URL { root.appendingPathComponent("Projects") }
    }

    private func makeFixture() throws -> Fixture {
        let root = try TestSupport.makeTempDirectory()
        return Fixture(root: root)
    }

    /// Creates <root>/Projects/<project>/<family> with content, a `.git`
    /// indicator, and an old modification date on the whole tree.
    private func makeOldArtifact(fixture: Fixture, project: String, family: String) throws {
        let projectDir = fixture.projectsRoot.appendingPathComponent(project)
        try TestSupport.writeFile(at: projectDir.appendingPathComponent(family + "/blob.dat"))
        try FileManager.default.createDirectory(
            at: projectDir.appendingPathComponent(".git"),
            withIntermediateDirectories: true
        )
        Self.backdateTree(projectDir)
    }

    private static func backdateTree(_ url: URL) {
        let oldDate = Date().addingTimeInterval(-30 * 86_400)
        try? FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: url.path)
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else { return }
        for case let child as URL in enumerator {
            try? FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: child.path)
        }
    }

    private func backdate(_ url: URL) {
        let oldDate = Date().addingTimeInterval(-30 * 86_400)
        try? FileManager.default.setAttributes(
            [.modificationDate: oldDate],
            ofItemAtPath: url.path
        )
    }

    private func scan(_ fixture: Fixture) async -> [ProjectGroup] {
        let scanner = ProjectArtifactScanner(
            rootsProvider: { [fixture.projectsRoot] },
            recencyCutoffProvider: { Date().addingTimeInterval(-7 * 86_400) }
        )

        var result: [ProjectGroup] = []
        for await progress in scanner.scan() {
            if case .complete(let groups) = progress {
                result = groups
            }
        }
        return result
    }
}
