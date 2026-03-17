import Foundation
import Testing
@testable import Broom

@Suite("UninstallArtifactPlanner")
struct UninstallArtifactPlannerTests {

    // MARK: - Name Variant Generation

    @Test func nameVariantsIncludesAllForms() {
        let variants = UninstallArtifactPlanner.nameVariants(for: "My Cool App")
        #expect(variants.contains("My Cool App"))
        #expect(variants.contains("MyCoolApp"))
        #expect(variants.contains("My-Cool-App"))
        #expect(variants.contains("My_Cool_App"))
        #expect(variants.contains("my cool app"))
        #expect(variants.contains("mycoolapp"))
        #expect(variants.contains("my-cool-app"))
        #expect(variants.contains("my_cool_app"))
    }

    @Test func nameVariantsDeduplicatesSingleWord() {
        let variants = UninstallArtifactPlanner.nameVariants(for: "Safari")
        #expect(variants.contains("Safari"))
        #expect(variants.contains("safari"))
        let safariCount = variants.filter { $0 == "Safari" }.count
        #expect(safariCount == 1)
    }

    @Test func channelSuffixTrimming() {
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Chrome Beta") == "Chrome")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Firefox Nightly") == "Firefox")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Edge Dev") == "Edge")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "VS Code Canary") == "VS Code")
    }

    @Test func versionSuffixTrimming() {
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "App 2.0") == "App")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "My Tool 3") == "My Tool")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Editor 1.2.3") == "Editor")
    }

    @Test func channelAndVersionCombinedTrimming() {
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "App Beta 2.0") == "App")
    }

    @Test func trimPreservesNameWhenNoSuffix() {
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Sublime Text") == "Sublime Text")
        #expect(UninstallArtifactPlanner.trimVersionAndChannel(from: "Xcode") == "Xcode")
    }

    @Test func nameVariantsWithChannelSuffix() {
        let variants = UninstallArtifactPlanner.nameVariants(for: "Chrome Beta")
        #expect(variants.contains("Chrome"))
        #expect(variants.contains("chrome"))
        #expect(!variants.contains("Chrome Beta"))
    }

    // MARK: - Artifact Discovery with Temp Directories

    @Test func discoversUserDataArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let appSupport = library.appendingPathComponent("Application Support")
        let bundleDir = appSupport.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "data".data(using: .utf8)?.write(to: bundleDir.appendingPathComponent("data.db"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let userDataItems = artifacts.filter { $0.source == .userData }
        #expect(userDataItems.contains(where: { pathsEqual($0.path, bundleDir) }))
    }

    @Test func discoversPreferencesArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let prefs = library.appendingPathComponent("Preferences")
        try FileManager.default.createDirectory(at: prefs, withIntermediateDirectories: true)
        let plistPath = prefs.appendingPathComponent("com.example.testapp.plist")
        try "plist-data".data(using: .utf8)?.write(to: plistPath)

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let prefItems = artifacts.filter { $0.source == .preferences }
        #expect(prefItems.contains(where: { pathsEqual($0.path, plistPath) }))
    }

    @Test func discoversCachesArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let caches = library.appendingPathComponent("Caches")
        let cacheDir = caches.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try "cache".data(using: .utf8)?.write(to: cacheDir.appendingPathComponent("cache.db"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let cacheItems = artifacts.filter { $0.source == .caches }
        #expect(cacheItems.contains(where: { pathsEqual($0.path, cacheDir) }))
    }

    @Test func discoversGroupContainerArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let groupContainers = library.appendingPathComponent("Group Containers")
        let groupDir = groupContainers.appendingPathComponent("group.com.example.testapp")
        try FileManager.default.createDirectory(at: groupDir, withIntermediateDirectories: true)
        try "group-data".data(using: .utf8)?.write(to: groupDir.appendingPathComponent("shared.db"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let groupItems = artifacts.filter { $0.source == .groupContainers }
        #expect(groupItems.contains(where: { pathsEqual($0.path, groupDir) }))
    }

    @Test func discoversWebDataArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")

        let webkit = library.appendingPathComponent("WebKit")
        let webkitDir = webkit.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: webkitDir, withIntermediateDirectories: true)
        try "web".data(using: .utf8)?.write(to: webkitDir.appendingPathComponent("data"))

        let cookies = library.appendingPathComponent("Cookies")
        try FileManager.default.createDirectory(at: cookies, withIntermediateDirectories: true)
        let cookiePath = cookies.appendingPathComponent("com.example.testapp.binarycookies")
        try "cookies".data(using: .utf8)?.write(to: cookiePath)

        let httpStorages = library.appendingPathComponent("HTTPStorages")
        let httpDir = httpStorages.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: httpDir, withIntermediateDirectories: true)
        try "http".data(using: .utf8)?.write(to: httpDir.appendingPathComponent("data"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let webItems = artifacts.filter { $0.source == .webData }
        #expect(webItems.count == 3)
        #expect(webItems.contains(where: { pathsEqual($0.path, webkitDir) }))
        #expect(webItems.contains(where: { pathsEqual($0.path, cookiePath) }))
        #expect(webItems.contains(where: { pathsEqual($0.path, httpDir) }))
    }

    @Test func discoversSavedStateArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let savedState = library.appendingPathComponent("Saved Application State")
        let stateDir = savedState.appendingPathComponent("com.example.testapp.savedState")
        try FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
        try "state".data(using: .utf8)?.write(to: stateDir.appendingPathComponent("data.data"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let stateItems = artifacts.filter { $0.source == .savedState }
        #expect(stateItems.count == 1)
        #expect(pathsEqual(stateItems.first?.path, stateDir))
    }

    @Test func discoversLogAndDiagnosticArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let logs = library.appendingPathComponent("Logs")
        let logDir = logs.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        try "log".data(using: .utf8)?.write(to: logDir.appendingPathComponent("app.log"))

        let diagnostics = logs.appendingPathComponent("DiagnosticReports")
        try FileManager.default.createDirectory(at: diagnostics, withIntermediateDirectories: true)
        try "crash".data(using: .utf8)?.write(to: diagnostics.appendingPathComponent("TestApp_2024-01-01.crash"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let logItems = artifacts.filter { $0.source == .logs }
        #expect(logItems.contains(where: { pathsEqual($0.path, logDir) }))
        #expect(logItems.contains(where: { $0.path.lastPathComponent.contains("TestApp") }))
    }

    @Test func discoversLaunchItemArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let userAgents = library.appendingPathComponent("LaunchAgents")
        try FileManager.default.createDirectory(at: userAgents, withIntermediateDirectories: true)
        let agentPlist = userAgents.appendingPathComponent("com.example.testapp.agent.plist")
        try "plist".data(using: .utf8)?.write(to: agentPlist)

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let launchItems = artifacts.filter { $0.source == .launchItems }
        #expect(launchItems.contains(where: { pathsEqual($0.path, agentPlist) }))
    }

    @Test func discoversHelperToolArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let helpers = root.appendingPathComponent("PrivilegedHelperTools")
        try FileManager.default.createDirectory(at: helpers, withIntermediateDirectories: true)
        let helperPath = helpers.appendingPathComponent("com.example.testapp.helper")
        try "binary".data(using: .utf8)?.write(to: helperPath)

        let planner = makePlanner(libraryRoot: root.appendingPathComponent("Library"), helperToolsDir: helpers)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let helperItems = artifacts.filter { $0.source == .helpers }
        #expect(helperItems.contains(where: { pathsEqual($0.path, helperPath) }))
    }

    @Test func discoversReceiptArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let receipts = root.appendingPathComponent("receipts")
        try FileManager.default.createDirectory(at: receipts, withIntermediateDirectories: true)
        let bomPath = receipts.appendingPathComponent("com.example.testapp.bom")
        let plistPath = receipts.appendingPathComponent("com.example.testapp.plist")
        try "bom".data(using: .utf8)?.write(to: bomPath)
        try "plist".data(using: .utf8)?.write(to: plistPath)

        let planner = makePlanner(libraryRoot: root.appendingPathComponent("Library"), receiptsDir: receipts)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let receiptItems = artifacts.filter { $0.source == .receipts }
        #expect(receiptItems.count == 2)
        #expect(receiptItems.contains(where: { pathsEqual($0.path, bomPath) }))
        #expect(receiptItems.contains(where: { pathsEqual($0.path, plistPath) }))
    }

    @Test func discoversAppScriptsArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let scripts = library.appendingPathComponent("Application Scripts")
        let scriptDir = scripts.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: scriptDir, withIntermediateDirectories: true)
        try "script".data(using: .utf8)?.write(to: scriptDir.appendingPathComponent("run.sh"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let scriptItems = artifacts.filter { $0.source == .appScripts }
        #expect(scriptItems.count == 1)
        #expect(pathsEqual(scriptItems.first?.path, scriptDir))
    }

    // MARK: - Deduplication

    @Test func deduplicatesArtifactsFromMultipleProviders() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")

        let appSupport = library.appendingPathComponent("Application Support")
        let bundleDir = appSupport.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "data".data(using: .utf8)?.write(to: bundleDir.appendingPathComponent("data.db"))

        let nameDir = appSupport.appendingPathComponent("TestApp")
        try FileManager.default.createDirectory(at: nameDir, withIntermediateDirectories: true)
        try "data".data(using: .utf8)?.write(to: nameDir.appendingPathComponent("data.db"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        let paths = artifacts.map { $0.path.standardizedFileURL.path }
        let uniquePaths = Set(paths)
        #expect(paths.count == uniquePaths.count)
    }

    // MARK: - Source Tagging

    @Test func allArtifactsHaveSourceTags() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let appSupport = library.appendingPathComponent("Application Support")
        let bundleDir = appSupport.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        try "data".data(using: .utf8)?.write(to: bundleDir.appendingPathComponent("data.db"))

        let caches = library.appendingPathComponent("Caches")
        let cacheDir = caches.appendingPathComponent("com.example.testapp")
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try "cache".data(using: .utf8)?.write(to: cacheDir.appendingPathComponent("cache.db"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "TestApp", bundleID: "com.example.testapp")
        let artifacts = planner.planArtifacts(for: app)

        for artifact in artifacts {
            #expect(artifact.source != nil, "Artifact at \(artifact.path) missing source tag")
        }
    }

    @Test func nameVariantMatchingDiscoversCacheByAppName() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        let caches = library.appendingPathComponent("Caches")
        let cacheDir = caches.appendingPathComponent("My Cool App")
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try "cache".data(using: .utf8)?.write(to: cacheDir.appendingPathComponent("data"))

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "My Cool App", bundleID: "com.example.mycoolapp")
        let artifacts = planner.planArtifacts(for: app)

        let cacheItems = artifacts.filter { $0.source == .caches }
        #expect(cacheItems.contains(where: { pathsEqual($0.path, cacheDir) }))
    }

    @Test func emptyDirectoryProducesNoArtifacts() throws {
        let root = try TestSupport.makeTempDirectory(prefix: "PlannerTest")
        defer { try? FileManager.default.removeItem(at: root) }

        let library = root.appendingPathComponent("Library")
        try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)

        let planner = makePlanner(libraryRoot: library)
        let app = makeApp(name: "Ghost", bundleID: "com.example.ghost")
        let artifacts = planner.planArtifacts(for: app)

        #expect(artifacts.isEmpty)
    }

    // MARK: - Test Helpers

    private func pathsEqual(_ a: URL?, _ b: URL) -> Bool {
        guard let a else { return false }
        return a.resolvingSymlinksInPath().standardizedFileURL.path
            == b.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private func makeApp(name: String, bundleID: String) -> InstalledApp {
        InstalledApp(
            name: name,
            bundleIdentifier: bundleID,
            bundlePath: URL(fileURLWithPath: "/Applications/\(name).app"),
            bundleSize: 1000
        )
    }

    private func makePlanner(
        libraryRoot: URL,
        helperToolsDir: URL? = nil,
        receiptsDir: URL? = nil
    ) -> TestableUninstallArtifactPlanner {
        TestableUninstallArtifactPlanner(
            libraryRoot: libraryRoot,
            helperToolsDir: helperToolsDir,
            receiptsDir: receiptsDir
        )
    }
}

private struct TestableUninstallArtifactPlanner {
    let libraryRoot: URL
    let helperToolsDir: URL?
    let receiptsDir: URL?
    private let fileManager = FileManager.default

    func planArtifacts(for app: InstalledApp) -> [CleanableItem] {
        let bundleID = app.bundleIdentifier.lowercased()
        let nameVariants = UninstallArtifactPlanner.nameVariants(for: app.name)
        var seen = Set<String>()
        var items: [CleanableItem] = []

        func append(_ item: CleanableItem) {
            let key = item.path.standardizedFileURL.path
            if seen.insert(key).inserted {
                items.append(item)
            }
        }

        for item in userDataArtifacts(bundleID: bundleID, nameVariants: nameVariants) { append(item) }
        for item in preferencesArtifacts(bundleID: bundleID) { append(item) }
        for item in cachesArtifacts(bundleID: bundleID, nameVariants: nameVariants) { append(item) }
        for item in groupContainerArtifacts(bundleID: bundleID) { append(item) }
        for item in webDataArtifacts(bundleID: bundleID) { append(item) }
        for item in savedStateArtifacts(bundleID: bundleID) { append(item) }
        for item in logsArtifacts(bundleID: bundleID, nameVariants: nameVariants) { append(item) }
        for item in launchItemsArtifacts(bundleID: bundleID) { append(item) }
        for item in helpersArtifacts(bundleID: bundleID) { append(item) }
        for item in receiptsArtifacts(bundleID: bundleID) { append(item) }
        for item in appScriptsArtifacts(bundleID: bundleID) { append(item) }

        return items.sorted { $0.size > $1.size }
    }

    private func userDataArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        let appSupport = libraryRoot.appendingPathComponent("Application Support")
        let containers = libraryRoot.appendingPathComponent("Containers")
        var items: [CleanableItem] = []

        if let item = artifactIfExists(appSupport.appendingPathComponent(bundleID), source: .userData, label: "Application Support") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(appSupport.appendingPathComponent(variant), source: .userData, label: "Application Support") {
                items.append(item)
            }
        }
        if let item = artifactIfExists(containers.appendingPathComponent(bundleID), source: .userData, label: "Containers") {
            items.append(item)
        }
        return items
    }

    private func preferencesArtifacts(bundleID: String) -> [CleanableItem] {
        let prefs = libraryRoot.appendingPathComponent("Preferences")
        let byHost = prefs.appendingPathComponent("ByHost")
        var items: [CleanableItem] = []

        let plistPath = prefs.appendingPathComponent("\(bundleID).plist")
        if let item = artifactIfExists(plistPath, source: .preferences, label: "Preferences") {
            items.append(item)
        }
        items.append(contentsOf: globMatchingEntries(in: byHost, pattern: bundleID, source: .preferences, label: "Preferences/ByHost"))
        return items
    }

    private func cachesArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        let caches = libraryRoot.appendingPathComponent("Caches")
        var items: [CleanableItem] = []

        if let item = artifactIfExists(caches.appendingPathComponent(bundleID), source: .caches, label: "Caches") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(caches.appendingPathComponent(variant), source: .caches, label: "Caches") {
                items.append(item)
            }
        }
        return items
    }

    private func groupContainerArtifacts(bundleID: String) -> [CleanableItem] {
        let groupContainers = libraryRoot.appendingPathComponent("Group Containers")
        return globMatchingEntries(in: groupContainers, pattern: bundleID, source: .groupContainers, label: "Group Containers")
    }

    private func webDataArtifacts(bundleID: String) -> [CleanableItem] {
        let webkit = libraryRoot.appendingPathComponent("WebKit")
        let cookies = libraryRoot.appendingPathComponent("Cookies")
        let httpStorages = libraryRoot.appendingPathComponent("HTTPStorages")
        var items: [CleanableItem] = []

        if let item = artifactIfExists(webkit.appendingPathComponent(bundleID), source: .webData, label: "WebKit") {
            items.append(item)
        }
        if let item = artifactIfExists(cookies.appendingPathComponent("\(bundleID).binarycookies"), source: .webData, label: "Cookies") {
            items.append(item)
        }
        if let item = artifactIfExists(httpStorages.appendingPathComponent(bundleID), source: .webData, label: "HTTPStorages") {
            items.append(item)
        }
        return items
    }

    private func savedStateArtifacts(bundleID: String) -> [CleanableItem] {
        let savedState = libraryRoot.appendingPathComponent("Saved Application State")
        let path = savedState.appendingPathComponent("\(bundleID).savedState")
        if let item = artifactIfExists(path, source: .savedState, label: "Saved Application State") {
            return [item]
        }
        return []
    }

    private func logsArtifacts(bundleID: String, nameVariants: [String]) -> [CleanableItem] {
        let logs = libraryRoot.appendingPathComponent("Logs")
        var items: [CleanableItem] = []

        if let item = artifactIfExists(logs.appendingPathComponent(bundleID), source: .logs, label: "Logs") {
            items.append(item)
        }
        for variant in nameVariants {
            if let item = artifactIfExists(logs.appendingPathComponent(variant), source: .logs, label: "Logs") {
                items.append(item)
            }
        }
        let diagnostics = logs.appendingPathComponent("DiagnosticReports")
        for variant in nameVariants {
            items.append(contentsOf: globMatchingEntries(in: diagnostics, pattern: variant, source: .logs, label: "DiagnosticReports"))
        }
        return items
    }

    private func launchItemsArtifacts(bundleID: String) -> [CleanableItem] {
        let userAgents = libraryRoot.appendingPathComponent("LaunchAgents")
        return globMatchingEntries(in: userAgents, pattern: bundleID, source: .launchItems, label: "Launch Agents")
    }

    private func helpersArtifacts(bundleID: String) -> [CleanableItem] {
        guard let dir = helperToolsDir else { return [] }
        return globMatchingEntries(in: dir, pattern: bundleID, source: .helpers, label: "Helpers")
    }

    private func receiptsArtifacts(bundleID: String) -> [CleanableItem] {
        guard let dir = receiptsDir else { return [] }
        return globMatchingEntries(in: dir, pattern: bundleID, source: .receipts, label: "Receipts")
    }

    private func appScriptsArtifacts(bundleID: String) -> [CleanableItem] {
        let scripts = libraryRoot.appendingPathComponent("Application Scripts")
        let path = scripts.appendingPathComponent(bundleID)
        if let item = artifactIfExists(path, source: .appScripts, label: "Application Scripts") {
            return [item]
        }
        return []
    }

    private func artifactIfExists(_ url: URL, source: UninstallArtifactSource, label: String) -> CleanableItem? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let size = itemSize(at: url)
        return CleanableItem(
            path: url,
            name: "\(label)/\(url.lastPathComponent)",
            size: size,
            source: source
        )
    }

    private func globMatchingEntries(in directory: URL, pattern: String, source: UninstallArtifactSource, label: String) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let lowerPattern = pattern.lowercased()
        return contents.compactMap { entry in
            let name = entry.lastPathComponent.lowercased()
            guard name.contains(lowerPattern) else { return nil }
            let size = itemSize(at: entry)
            return CleanableItem(
                path: entry,
                name: "\(label)/\(entry.lastPathComponent)",
                size: size,
                source: source
            )
        }
    }

    private func itemSize(at url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }

        if !isDirectory.boolValue {
            return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }

        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]
            ) else { continue }
            if values.isRegularFile == true {
                totalSize += Int64(values.totalFileAllocatedSize ?? 0)
            }
        }
        return totalSize
    }
}
