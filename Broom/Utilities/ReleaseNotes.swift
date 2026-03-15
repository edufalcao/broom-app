import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.1.0"
    static let previousVersion = "1.0.0"
    static let currentReleaseDate = "2026-03-15"

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            title: "Cleaner",
            items: [
                "Orphaned app leftovers are now detected and merged into real scan results.",
                "Cleaning settings now control developer-cache scans, .DS_Store scans, temp-file age, and delete behavior.",
                "Running apps are detected before cleaning so you can skip active-app caches or continue intentionally."
            ]
        ),
        ReleaseNoteSection(
            title: "Uninstaller",
            items: [
                "Dropped .app bundles now open an uninstall preview even when they were not already indexed.",
                "App sizes include associated files, so size sorting reflects the full uninstall footprint.",
                "Uninstall previews now support per-file selection plus Trash or permanent-delete choices."
            ]
        ),
        ReleaseNoteSection(
            title: "App Polish",
            items: [
                "The Apps view keeps visible separators between the sidebar, list, and detail panes even when the window is inactive.",
                "Keyboard shortcuts and toolbar navigation remain aligned with the split-view layout."
            ]
        ),
        ReleaseNoteSection(
            title: "Quality",
            items: [
                "Added expanded automated coverage for scanner, orphan detection, settings, cleaning, inventory, and uninstall flows."
            ]
        )
    ]
}
