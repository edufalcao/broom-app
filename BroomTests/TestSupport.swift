import Foundation
import Testing
@testable import Broom

enum TestSupport {
    static func makeTempDirectory(prefix: String = "BroomTests") throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func writeFile(
        at url: URL,
        contents: String = "test-data"
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
    }

    /// Writes a file with enough content to exceed the orphan detector's minimum size threshold (4KB).
    static func writeOrphanFile(
        at url: URL,
        size: Int = 5000,
        modificationDate: Date? = nil
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = Data(repeating: 0x41, count: size)
        try data.write(to: url)

        if let modDate = modificationDate {
            try FileManager.default.setAttributes(
                [.modificationDate: modDate],
                ofItemAtPath: url.path
            )
        }
    }

    /// Sets the modification date for a file or directory.
    static func setModificationDate(_ date: Date, at url: URL) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: url.path
        )
    }

    static func makeAppBundle(
        at root: URL,
        name: String,
        bundleIdentifier: String,
        version: String = "1.0"
    ) throws -> URL {
        let appURL = root.appendingPathComponent("\(name).app")
        let contentsURL = appURL.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": name,
            "CFBundleShortVersionString": version,
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))
        try writeFile(at: contentsURL.appendingPathComponent("MacOS/\(name)"), contents: "binary")
        return appURL
    }

    static func awaitCondition(
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        pollNanoseconds: UInt64 = 20_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let start = ContinuousClock.now
        while await !condition() {
            if ContinuousClock.now.duration(to: start).components.attoseconds.magnitude > 0 {
                // no-op; keeps the compiler from optimizing the loop incorrectly in tests
            }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
            if ContinuousClock.now - start > .nanoseconds(Int64(timeoutNanoseconds)) {
                Issue.record("Condition timed out")
                return
            }
        }
    }

    static func collectScanResult(from scanner: FileScanner) async -> ScanResult? {
        for await progress in scanner.scanAll() {
            if case .complete(let result) = progress {
                return result
            }
        }
        return nil
    }
}

final class MockScanner: ScanServing {
    var streamFactory: () -> AsyncStream<ScanProgress>

    init(streamFactory: @escaping () -> AsyncStream<ScanProgress>) {
        self.streamFactory = streamFactory
    }

    func scanAll() -> AsyncStream<ScanProgress> {
        streamFactory()
    }
}

final class MockOrphanDetector: OrphanDetecting {
    var orphans: [OrphanedApp]

    init(orphans: [OrphanedApp]) {
        self.orphans = orphans
    }

    func detectOrphans() async -> [OrphanedApp] {
        orphans
    }
}

final class MockCleaner: CleanServing {
    var lastItems: [CleanableItem] = []
    var lastMoveToTrash = true
    var report: CleanReport

    init(report: CleanReport = CleanReport(freedBytes: 0, itemsCleaned: 0, itemsFailed: 0, errors: [], duration: 0)) {
        self.report = report
    }

    func clean(items: [CleanableItem], moveToTrash: Bool) -> AsyncStream<CleanProgress> {
        lastItems = items
        lastMoveToTrash = moveToTrash

        return AsyncStream { continuation in
            continuation.yield(.progress(current: items.count, total: items.count, currentPath: items.last?.name ?? ""))
            continuation.yield(.complete(report))
            continuation.finish()
        }
    }
}

final class MockLargeFileScanner: LargeFileScanning, @unchecked Sendable {
    let files: [LargeFile]

    init(files: [LargeFile] = []) {
        self.files = files
    }

    nonisolated func scan(root: URL, minimumSize: Int64) -> AsyncStream<LargeFileScanProgress> {
        let files = self.files
        return AsyncStream { continuation in
            continuation.yield(.complete(files))
            continuation.finish()
        }
    }
}

final class MockAppInventory: AppInventoryServing {
    var apps: [InstalledApp]
    var bundleIdentifiers: Set<String>
    var associatedFiles: [String: [CleanableItem]]
    var droppedApps: [URL: InstalledApp]
    var snapshot: InstalledAppSnapshot

    init(
        apps: [InstalledApp] = [],
        bundleIdentifiers: Set<String> = [],
        associatedFiles: [String: [CleanableItem]] = [:],
        droppedApps: [URL: InstalledApp] = [:],
        snapshot: InstalledAppSnapshot = InstalledAppSnapshot(
            installedBundleIDs: [],
            installedAppURLs: [],
            runningBundleIDs: [],
            launchItemLabels: []
        )
    ) {
        self.apps = apps
        self.bundleIdentifiers = bundleIdentifiers
        self.associatedFiles = associatedFiles
        self.droppedApps = droppedApps
        self.snapshot = snapshot
    }

    func loadAllApps() async -> [InstalledApp] {
        apps
    }

    func loadApp(at url: URL) async -> InstalledApp? {
        droppedApps[url]
    }

    func installedBundleIdentifiers() async -> Set<String> {
        bundleIdentifiers
    }

    func findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem] {
        associatedFiles[bundleID] ?? []
    }

    func buildSnapshot() async -> InstalledAppSnapshot {
        snapshot
    }
}

final class MockAppUninstaller: AppUninstalling {
    var preparedPlan: UninstallPlan
    var lastExecutedPlan: UninstallPlan?
    var lastMoveToTrash = true
    var report: CleanReport

    init(
        preparedPlan: UninstallPlan,
        report: CleanReport = CleanReport(freedBytes: 0, itemsCleaned: 0, itemsFailed: 0, errors: [], duration: 0)
    ) {
        self.preparedPlan = preparedPlan
        self.report = report
    }

    func prepareUninstall(app: InstalledApp) async -> UninstallPlan {
        preparedPlan
    }

    func executeUninstall(plan: UninstallPlan, moveToTrash: Bool) -> AsyncStream<CleanProgress> {
        lastExecutedPlan = plan
        lastMoveToTrash = moveToTrash

        return AsyncStream { continuation in
            continuation.yield(.progress(current: plan.filesToRemove.count, total: plan.filesToRemove.count, currentPath: plan.filesToRemove.last?.name ?? ""))
            continuation.yield(.complete(report))
            continuation.finish()
        }
    }
}
