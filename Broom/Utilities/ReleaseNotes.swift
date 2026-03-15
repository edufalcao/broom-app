import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.2.0"
    static let previousVersion = "1.1.0"
    static let currentReleaseDate = "2026-03-15"

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            title: "Large File Finder",
            items: [
                "New sidebar tab to scan your home directory for large files (100 MB+).",
                "Sort results by size, name, or modified date.",
                "Configurable minimum size threshold (100 MB, 250 MB, 500 MB, 1 GB).",
                "Reveal any file in Finder with one click.",
            ]
        ),
        ReleaseNoteSection(
            title: "Cleaner",
            items: [
                "Docker cleanup: scan Docker VM disk images and configuration.",
                "Homebrew cleanup: detect old formula versions and cached downloads.",
                "App Leftovers now appear as a regular category row with drill-in detail.",
                "Confidence badges preserved on each leftover item.",
            ]
        ),
        ReleaseNoteSection(
            title: "Orphan Detection",
            items: [
                "Receipt database: reads /var/db/receipts to identify apps installed via .pkg.",
                "Spotlight metadata: queries macOS for previously indexed bundle IDs.",
                "Improved confidence scoring using receipts, Spotlight, and Saved Application State.",
            ]
        ),
        ReleaseNoteSection(
            title: "App Polish",
            items: [
                "Dock icon badge shows total junk size after scan, clears after cleaning.",
                "VoiceOver accessibility labels on all key interactive elements.",
                "Safe List empty state with description instead of blank screen.",
            ]
        ),
        ReleaseNoteSection(
            title: "Quality",
            items: [
                "57 tests across 19 suites covering all new features.",
            ]
        ),
    ]
}
