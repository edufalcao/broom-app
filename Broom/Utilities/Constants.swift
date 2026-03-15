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

    // MARK: - Developer Caches

    static let spmCache = userCaches.appendingPathComponent("org.swift.swiftpm")
    static let cocoapodsCache = userCaches.appendingPathComponent("CocoaPods")
    static let homebrewCache = userCaches.appendingPathComponent("Homebrew")
    static let npmCache = home.appendingPathComponent(".npm/_cacache")
    static let yarnCache = userCaches.appendingPathComponent("Yarn")
    static let pipCache = userCaches.appendingPathComponent("pip")

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

    // MARK: - Protected Bundle ID Prefixes

    static let protectedBundleIDPrefixes: Set<String> = [
        "com.apple.",
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

    // MARK: - Application Directories

    static let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        home.appendingPathComponent("Applications"),
    ]

    static let systemApplicationsDirectory = URL(fileURLWithPath: "/System/Applications")
    static let userLaunchAgents = library.appendingPathComponent("LaunchAgents")
    static let systemLaunchAgents = URL(fileURLWithPath: "/Library/LaunchAgents")
    static let systemLaunchDaemons = URL(fileURLWithPath: "/Library/LaunchDaemons")
}
