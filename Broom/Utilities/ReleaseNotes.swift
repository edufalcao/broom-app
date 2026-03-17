import Foundation

struct ReleaseNoteSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}

enum ReleaseNotes {
    static let currentVersion = "1.2.0"
    static let currentReleaseDate = "2026-03-17"

    static let versions: [(version: String, date: String, sections: [ReleaseNoteSection])] = [
        (
            version: "1.2.0",
            date: "2026-03-17",
            sections: [
                ReleaseNoteSection(
                    title: "Uninstall",
                    items: [
                        "Sidebar renamed from \"Apps\" to \"Uninstall\" for clarity.",
                        "Uninstall tab starts with an idle screen and a \"Scan Apps\" button instead of auto-scanning.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Leftover Detection",
                    items: [
                        "All com.apple.* entries are broadly suppressed from orphan detection — system data is never listed as leftovers.",
                        "Group Container entries with team ID prefixes (e.g., UBF8T346G9.com.microsoft.teams) are now correctly matched against installed apps.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Quality",
                    items: [
                        "168 tests across 27 suites.",
                    ]
                ),
            ]
        ),
        (
            version: "1.1.0",
            date: "2026-03-17",
            sections: [
                ReleaseNoteSection(
                    title: "Smarter App Cleanup",
                    items: [
                        "Uninstalls now remove launch agents, login items, privileged helpers, package receipts, application scripts, and ByHost preferences.",
                        "LaunchServices metadata is cleaned up after uninstall: the app is unregistered and the database is refreshed.",
                        "Uninstall preview groups artifacts by source (User Data, Preferences, Launch Items, etc.) with section headers.",
                        "Name variant generation finds artifacts stored under non-standard names (hyphenated, underscored, version-trimmed).",
                        "\"Back to apps list\" button on the uninstall success screen.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Trustworthy Leftover Detection",
                    items: [
                        "Orphan detection uses a suppression-first architecture with 9 gates: only stale, high-confidence leftovers are shown.",
                        "Recently active, running, or ambiguous items are automatically excluded from results.",
                        "Stale-age threshold (default 30 days) is configurable in Settings.",
                        "Spotlight and receipt signals are used to suppress false positives rather than inflate confidence.",
                        "Select All checkbox at the top of scan results.",
                        "Low-confidence items shown in a separate dimmed section for review.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Protected Data",
                    items: [
                        "Sensitive app data is never surfaced in generic cleanup scans.",
                        "Protected families: password managers, VPNs, browsers, AI tools, iCloud-synced data, and automation tools.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Stronger Safety",
                    items: [
                        "Every deletion is validated through DeletePolicy before executing: path safety, symlink resolution, and protected-data checks.",
                        "Structured DeleteResult replaces raw success/failure, making blocked operations visible in logs and reports.",
                        "Receipts under /var/db/receipts are accessible during explicit uninstalls but blocked in generic scans.",
                        "Running app detection uses precise matching to avoid false positives from system processes.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Performance",
                    items: [
                        "App list loads significantly faster using Spotlight metadata for bundle sizes.",
                        "Associated files load on demand when an app is selected, not upfront for all apps.",
                        "Apple and system apps are filtered from the uninstaller list.",
                    ]
                ),
                ReleaseNoteSection(
                    title: "Quality",
                    items: [
                        "162 tests across 27 suites (up from 72 across 21).",
                    ]
                ),
            ]
        ),
        (
            version: "1.0.0",
            date: "2026-03-15",
            sections: [
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
        ),
    ]

    static let sections: [ReleaseNoteSection] = versions.first?.sections ?? []
}
