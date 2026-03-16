import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.3.0"
    static let previousVersion = "1.2.1"
    static let currentReleaseDate = "2026-03-15"

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            title: "Cleaner Defaults & Coverage",
            items: [
                "Default temporary-file age is now consistently 7 days across runtime, settings, and docs.",
                "Notifications now default to enabled on first launch instead of silently staying off until toggled.",
                "Downloads appears as an awareness-only cleaner category and starts unselected.",
                "System scans now execute categories concurrently while preserving stable result ordering.",
            ]
        ),
        ReleaseNoteSection(
            title: "Uninstaller & Inventory",
            items: [
                "Installed-app inventory now supports Spotlight-supplemented discovery for apps outside standard folders.",
                "Running app uninstall flow now offers a force-quit fallback when a normal quit does not work.",
                "About settings now include a GitHub link and author credit.",
            ]
        ),
        ReleaseNoteSection(
            title: "Documentation & Safety",
            items: [
                "README, PRD, architecture, and implementation status docs now reflect the current sidebar and cleaner behavior.",
                "Categories that default to unselected now correctly start with every item unselected as well.",
            ]
        ),
        ReleaseNoteSection(
            title: "Quality",
            items: [
                "72 tests across 21 suites.",
            ]
        ),
    ]
}
