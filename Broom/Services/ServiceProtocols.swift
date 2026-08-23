import Foundation

protocol ScanServing {
    func scanAll() -> AsyncStream<ScanProgress>
}

protocol OrphanDetecting {
    func detectOrphans() async -> [OrphanedApp]
}

protocol CleanServing {
    func clean(items: [CleanableItem], moveToTrash: Bool) -> AsyncStream<CleanProgress>
}

protocol AppInventoryServing {
    func loadAllApps() async -> [InstalledApp]
    func loadApp(at url: URL) async -> InstalledApp?
    func installedBundleIdentifiers() async -> Set<String>
    func findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem]
    func buildSnapshot() async -> InstalledAppSnapshot
}

protocol AppUninstalling {
    /// Planner-discovered artifacts for an app. These are merged into the
    /// app's editable associated-file list before a plan is built, so the
    /// detail view, confirmation sheet, and execution always describe the
    /// same file set.
    func discoverArtifacts(for app: InstalledApp) async -> [CleanableItem]
    func executeUninstall(plan: UninstallPlan, moveToTrash: Bool) -> AsyncStream<CleanProgress>
}

protocol LargeFileScanning {
    nonisolated func scan(root: URL, minimumSize: Int64) -> AsyncStream<LargeFileScanProgress>
}
