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
}

protocol AppUninstalling {
    func prepareUninstall(app: InstalledApp) async -> UninstallPlan
    func executeUninstall(plan: UninstallPlan, moveToTrash: Bool) -> AsyncStream<CleanProgress>
}
