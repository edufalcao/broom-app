import AppKit

enum RunningAppDetector {
    static func runningBundleIdentifiers() -> Set<String> {
        Set(
            NSWorkspace.shared.runningApplications
                .compactMap(\.bundleIdentifier)
                .map { $0.lowercased() }
        )
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
}
