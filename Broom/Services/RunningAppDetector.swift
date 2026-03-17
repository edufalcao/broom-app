import AppKit

struct RunningApplicationInfo: Equatable {
    let bundleIdentifier: String
    let localizedName: String
}

enum RunningAppDetector {
    static func runningApplications() -> [RunningApplicationInfo] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard let bundleIdentifier = app.bundleIdentifier?.lowercased() else { return nil }
            let localizedName = app.localizedName?.lowercased() ?? ""
            return RunningApplicationInfo(
                bundleIdentifier: bundleIdentifier,
                localizedName: localizedName
            )
        }
    }

    static func runningBundleIdentifiers() -> Set<String> {
        Set(runningApplications().map(\.bundleIdentifier))
    }

    static func isRunning(bundleIdentifier: String) -> Bool {
        runningBundleIdentifiers().contains(bundleIdentifier.lowercased())
    }

    static func terminate(bundleIdentifier: String) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier?.lowercased() == bundleIdentifier.lowercased() })
        else { return false }
        return app.terminate()
    }

    static func forceTerminate(bundleIdentifier: String) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier?.lowercased() == bundleIdentifier.lowercased() })
        else { return false }
        return app.forceTerminate()
    }

    static func matchingApplications(
        for items: [CleanableItem],
        runningApplications: [RunningApplicationInfo] = runningApplications()
    ) -> [RunningApplicationInfo] {
        runningApplications.filter { app in
            items.contains { matches(item: $0, runningApplication: app) }
        }
    }

    static func matches(item: CleanableItem, runningApplication: RunningApplicationInfo) -> Bool {
        let path = item.path.path.lowercased()
        let name = item.name.lowercased()
        let appName = runningApplication.localizedName

        if path.contains(runningApplication.bundleIdentifier) {
            return true
        }

        let bundleParts = runningApplication.bundleIdentifier.split(separator: ".")
        if let lastPart = bundleParts.last, lastPart.count >= 3 {
            let lowerPart = String(lastPart).lowercased()
            let pathComponents = item.path.pathComponents.map { $0.lowercased() }
            if pathComponents.contains(lowerPart) {
                return true
            }
        }

        if !appName.isEmpty, appName.count >= 3,
           name.contains(appName) || appName.contains(name) {
            return true
        }

        return false
    }
}
