import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.2.1"
    static let previousVersion = "1.2.0"
    static let currentReleaseDate = "2026-03-15"

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            title: "Settings & Navigation",
            items: [
                "Settings now opens as a native macOS Settings window (Cmd+,).",
                "Toolbar gear button uses SettingsLink for standard macOS behavior.",
                "Category drill-in uses NavigationStack for proper push/pop transitions.",
            ]
        ),
        ReleaseNoteSection(
            title: "Accessibility & Polish",
            items: [
                "Category rows are now proper Buttons for full VoiceOver and keyboard support.",
                "Smooth fade animations on all state transitions (scan, clean, done).",
                "Clean complete screen shows correct action (Trash vs permanently deleted).",
                "Uninstall confirmation sheet adapts to content height.",
            ]
        ),
        ReleaseNoteSection(
            title: "Architecture",
            items: [
                "Replaced NotificationCenter with type-safe AppRouter for cross-component actions.",
                "Added @MainActor to UninstallerViewModel for concurrency safety.",
                "Large Files scanner now supports dependency injection for testability.",
                "Cached date formatters in list rows for better scroll performance.",
            ]
        ),
        ReleaseNoteSection(
            title: "Quality",
            items: [
                "65 tests across 20 suites.",
            ]
        ),
    ]
}
