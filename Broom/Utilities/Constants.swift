import Foundation

enum Constants {
    // MARK: - App Identity

    static let bundleIdentifier = "com.broom.app"
    static let appSupportDirectory: URL = {
        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return path.appendingPathComponent("Broom")
    }()
    static let safeListPath: URL = appSupportDirectory.appendingPathComponent("safelist.json")

    // MARK: - Home & Library

    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let library = home.appendingPathComponent("Library")

    // MARK: - System Caches

    static let userCaches = library.appendingPathComponent("Caches")

    // MARK: - Browser Caches

    static let chromeCachePaths: [URL] = {
        let chromeBase = userCaches.appendingPathComponent("Google/Chrome")
        return [
            chromeBase.appendingPathComponent("Default/Cache"),
            chromeBase.appendingPathComponent("Default/Code Cache"),
        ]
    }()

    static let firefoxCache = userCaches.appendingPathComponent("org.mozilla.firefox")
    static let safariCache = userCaches.appendingPathComponent("com.apple.Safari")
    static let arcCache = userCaches.appendingPathComponent("company.thebrowser.Browser")
    static let braveCache = userCaches.appendingPathComponent("BraveSoftware/Brave-Browser/Default/Cache")
    static let edgeCache = userCaches.appendingPathComponent("com.microsoft.edgemac")

    // Extended browser breadth
    static let vivaldiCache = userCaches.appendingPathComponent("com.vivaldi.Vivaldi")
    static let operaCache = userCaches.appendingPathComponent("com.operasoftware.Opera")
    static let yandexCacheBase = userCaches.appendingPathComponent("Yandex/YandexBrowser")
    static let orionCache = userCaches.appendingPathComponent("com.kagi.kagimacOS")
    static let zenCache = userCaches.appendingPathComponent("zen")
    static let cometCache = userCaches.appendingPathComponent("Comet")
    static let heliumCache = userCaches.appendingPathComponent("net.imput.helium")
    static let qqBrowserCache = userCaches.appendingPathComponent("com.tencent.QQBrowser3")
    static let thunderbirdCache = userCaches.appendingPathComponent("org.mozilla.thunderbird")
    static let diaCacheBase = userCaches.appendingPathComponent("Dia/User Data")

    // MARK: - Apple System Data

    static let savedApplicationState = library.appendingPathComponent("Saved Application State")
    static let messagesStickerCache = home.appendingPathComponent("Messages/StickerCache")
    static let messagesPreviewStickerCache = home.appendingPathComponent("Messages/Caches/Previews/StickerCache")

    // MARK: - Logs

    static let userLogs = library.appendingPathComponent("Logs")
    static let systemLogs = URL(fileURLWithPath: "/Library/Logs")
    static let diagnosticReports = userLogs.appendingPathComponent("DiagnosticReports")

    // MARK: - Temporary Files

    static let userTmpDir: URL = {
        URL(fileURLWithPath: NSTemporaryDirectory())
    }()
    static let systemTmp = URL(fileURLWithPath: "/tmp")

    // MARK: - Xcode

    static let xcodeDerivedData = library.appendingPathComponent("Developer/Xcode/DerivedData")
    static let xcodeArchives = library.appendingPathComponent("Developer/Xcode/Archives")

    // MARK: - Xcode Simulator

    static let simulatorCaches = library.appendingPathComponent("Developer/CoreSimulator/Caches")
    static let simulatorDevices = library.appendingPathComponent("Developer/CoreSimulator/Devices")
    static let simulatorLogs = userLogs.appendingPathComponent("CoreSimulator")

    // MARK: - Developer Caches

    static let spmCache = userCaches.appendingPathComponent("org.swift.swiftpm")
    static let cocoapodsCache = userCaches.appendingPathComponent("CocoaPods")
    static let homebrewCache = userCaches.appendingPathComponent("Homebrew")
    static let npmCache = home.appendingPathComponent(".npm/_cacache")
    static let yarnCache = userCaches.appendingPathComponent("Yarn")
    static let pipCache = userCaches.appendingPathComponent("pip")

    // Extended developer caches (filesystem-only)
    static let cargoRegistryCache = home.appendingPathComponent(".cargo/registry/cache")
    static let bunInstallCache = home.appendingPathComponent(".bun/install/cache")
    static let corepackCacheCandidates: [URL] = [
        home.appendingPathComponent(".cache/node/corepack"),
        userCaches.appendingPathComponent("node/corepack"),
    ]
    static let rbenvCache = home.appendingPathComponent(".rbenv/cache")
    static let gemSpecsCache = home.appendingPathComponent(".gem/specs")
    static let bundlerCache = home.appendingPathComponent(".bundle/cache")

    // MARK: - Docker

    static let dockerData = library.appendingPathComponent("Containers/com.docker.docker/Data/vms")
    static let dockerConfig = home.appendingPathComponent(".docker")

    // MARK: - Homebrew

    static let homebrewCellar: URL = {
        // ARM Mac: /opt/homebrew, Intel: /usr/local
        let armPath = URL(fileURLWithPath: "/opt/homebrew/Cellar")
        let intelPath = URL(fileURLWithPath: "/usr/local/Cellar")
        return FileManager.default.fileExists(atPath: armPath.path) ? armPath : intelPath
    }()

    // MARK: - Mail

    static let mailAttachments = library.appendingPathComponent(
        "Containers/com.apple.mail/Data/Library/Mail Downloads"
    )

    // MARK: - Downloads

    static let downloads = home.appendingPathComponent("Downloads")

    // MARK: - Library Subdirectories (for orphan/app scanning)

    static let librarySubdirectories: [URL] = [
        library.appendingPathComponent("Application Support"),
        userCaches,
        library.appendingPathComponent("Preferences"),
        library.appendingPathComponent("Containers"),
        library.appendingPathComponent("Group Containers"),
        library.appendingPathComponent("Saved Application State"),
        library.appendingPathComponent("WebKit"),
        library.appendingPathComponent("HTTPStorages"),
    ]

    // MARK: - Protected Bundle / Container Prefixes

    static let protectedBundleIDPrefixes: Set<String> = [
        "com.apple.",
        "group.com.apple.",
        "com.electron.",
        "org.chromium.",
    ]

    // MARK: - System-Critical Caches (never delete)

    static let protectedCacheIdentifiers: Set<String> = [
        "com.apple.iconservices",
        "com.apple.dock",
        "com.apple.Spotlight",
        "com.apple.bird",
        "com.apple.nsurlsessiond",
        "CloudKit",
        "com.apple.LaunchServices",
    ]

    // MARK: - Protected Preference Files

    static let protectedPreferenceFiles: Set<String> = [
        "mobilemeaccounts.plist",
    ]

    // MARK: - Application Directories

    static let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        home.appendingPathComponent("Applications"),
    ]

    static let extendedAppDiscoveryRoots: [URL] = [
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/opt/homebrew/Caskroom"),
        URL(fileURLWithPath: "/usr/local/Caskroom"),
        library.appendingPathComponent("Application Support/Setapp/Applications"),
    ]

    static let systemApplicationsDirectory = URL(fileURLWithPath: "/System/Applications")
    static let userLaunchAgents = library.appendingPathComponent("LaunchAgents")
    static let systemLaunchAgents = URL(fileURLWithPath: "/Library/LaunchAgents")
    static let systemLaunchDaemons = URL(fileURLWithPath: "/Library/LaunchDaemons")

    // MARK: - Project Artifacts

    /// UserDefaults key holding the user's custom search roots.
    static let projectArtifactRootsKey = "projectArtifactRoots"

    static let defaultProjectArtifactRoots: [URL] = [
        home.appendingPathComponent("Projects"),
        home.appendingPathComponent("dev"),
        home.appendingPathComponent("www"),
        home.appendingPathComponent("GitHub"),
        home.appendingPathComponent("Code"),
        home.appendingPathComponent("Workspace"),
        home.appendingPathComponent("Repos"),
        home.appendingPathComponent("Development"),
        library.appendingPathComponent("CloudStorage"),
    ]

    /// Directory names treated as regenerable build artifacts.
    /// DerivedData deliberately absent: it is a shared store owned by the Cleaner.
    static let projectArtifactFamilies: Set<String> = [
        "node_modules", "target", "build", "dist", "venv", ".venv",
        ".pytest_cache", ".mypy_cache", ".tox", ".nox", ".ruff_cache",
        ".gradle", ".terragrunt-cache", "__pycache__", ".next", ".nuxt",
        ".output", "vendor", "obj", ".turbo", ".parcel-cache", ".dart_tool",
        ".zig-cache", "zig-out", ".angular", ".svelte-kit", ".astro",
        "coverage", "Pods", ".cxx", ".expo", ".build",
    ]

    /// Files whose presence marks a directory as a project root. `.git`
    /// doubles as the monorepo marker.
    static let projectIndicatorNames: Set<String> = [
        ".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml",
        "requirements.txt", "pom.xml", "build.gradle", "Gemfile",
        "composer.json", "pubspec.yaml", "Package.swift", "Makefile",
        "build.zig", "project.yml",
    ]

    /// Standard marker declaring a directory safe to delete wholesale.
    static let cacheDirTag = "CACHEDIR.TAG"
}
