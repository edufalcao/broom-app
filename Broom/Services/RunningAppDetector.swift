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

        for token in candidateTokens(for: runningApplication) where token.count >= 3 {
            if name.contains(token) || path.contains(token) {
                return true
            }
        }

        return false
    }

    private static func candidateTokens(for app: RunningApplicationInfo) -> Set<String> {
        var tokens: Set<String> = [app.bundleIdentifier, app.localizedName]
        let bundleParts = app.bundleIdentifier.split(separator: ".").map(String.init)

        if let last = bundleParts.last {
            tokens.insert(last.lowercased())
        }

        for part in bundleParts where part.count >= 3 {
            tokens.insert(part.lowercased())
        }

        let compactName = app.localizedName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        if compactName.count >= 3 {
            tokens.insert(compactName)
        }

        return tokens.filter { !$0.isEmpty }
    }
}
