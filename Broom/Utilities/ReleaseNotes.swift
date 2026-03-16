import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.0.0"
    static let currentReleaseDate = "2026-03-15"

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            title: "System Cleaner",
            items: [
                "Scans system and browser caches, logs, crash reports, temporary files, developer caches, Docker data, Homebrew data, Mail downloads, Downloads awareness, and .DS_Store files.",
                "Temporary files default to a 7-day age threshold, and notifications are enabled by default.",
                "Cleaner categories scan concurrently while preserving stable result ordering in the UI.",
            ]
        ),
        ReleaseNoteSection(
            title: "App Cleanup",
            items: [
                "Detects orphaned app leftovers with confidence scoring and shows them directly in scan results.",
                "Installed-app inventory includes Spotlight-supplemented discovery for apps outside standard folders.",
                "App uninstall previews include associated Library files plus launch agents and daemons.",
                "Running-app uninstall flow supports graceful quit and force-quit fallback when needed.",
            ]
        ),
        ReleaseNoteSection(
            title: "Large Files & Safety",
            items: [
                "Large File Finder scans the home directory for files above 100 MB, 250 MB, 500 MB, or 1 GB.",
                "Broom previews all destructive actions and moves files to Trash by default.",
                "The About tab links to GitHub and Eduardo Falcão's website.",
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
