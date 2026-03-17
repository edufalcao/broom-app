# Changelog

All notable changes to Broom will be documented in this file.

## [Unreleased]

## [1.3.0] - 2026-03-17

### Added
- Container metadata reading for Group Containers and Application Scripts — suppresses entries owned by installed apps via `.com.apple.containermanagerd.metadata.plist`
- Embedded helper bundle ID discovery: installed-app snapshots now include bundle IDs from embedded `.app`, `.appex`, and `.xpc` bundles within app hierarchies
- Descendant-aware stale-age evaluation: directory candidates use the newest file modification date, not just the top-level folder timestamp
- Explicit suppression for Apple-managed account preferences (`MobileMeAccounts.plist`)
- Regression tests for Teams migration containers, Apple group containers, embedded helper bundles, recent descendant activity, creator metadata ownership, and container-only confidence

### Changed
- Apple-managed group containers (`group.com.apple.*`) are now suppressed from orphan detection
- Container-only candidates default to lower confidence unless stronger signals (receipts, saved-state) exist
- Orphan detection expanded from 9 to 10 suppression gates (added managed container ownership check)

### Quality
- 176 tests across 27 suites (up from 168)

## [1.2.0] - 2026-03-17

### Changed
- Sidebar label renamed from "Apps" to "Uninstall" for clarity
- Uninstall tab starts with an idle screen and "Scan Apps" button instead of auto-scanning on tab switch
- All `com.apple.*` entries are now broadly suppressed from orphan detection — system and framework data is never listed as leftovers
- Group Container entries with team ID prefixes (e.g., `UBF8T346G9.com.microsoft.teams`) are now correctly matched against installed apps

### Quality
- 168 tests across 27 suites (up from 162)

## [1.1.0] - 2026-03-17

### Added
- Uninstall artifact planner with 11 providers: user data, preferences, caches, group containers, web data, saved state, logs, launch items, helpers, receipts, and app scripts
- Name variant generation for artifact discovery (no-space, hyphenated, underscored, lowercase, version/channel trimmed)
- LaunchServices metadata cleanup: unregister apps and refresh database after uninstall
- Login item cleanup: unload launch agents and daemons before deleting their files
- Uninstall preview grouped by artifact source with section headers
- Protected data policy covering 6 families: password managers, VPNs, browsers, AI tools, iCloud data, and automation tools
- Delete policy with path safety validation, symlink resolution checks, and context-dependent protected-data enforcement
- Structured DeleteResult type (success/blocked/failed) replacing raw success/failure
- InstalledAppSnapshot for point-in-time system state used by orphan detection
- Orphan stale-age threshold setting (default 30 days, configurable in Settings)
- Select All checkbox at the top of scan results category list
- "Back to apps list" button on uninstall success screen
- Low-confidence orphan items shown in a separate dimmed section within category detail
- Orphan results messaging explaining conservative policy
- DeletePolicyTests, ProtectedDataPolicyTests, UninstallArtifactPlannerTests, and MetadataCleanupTests suites

### Changed
- Orphan detection rewritten with suppression-first architecture: 9 gates filter candidates before they reach results
- Orphan candidates restricted to strict patterns only (reverse-DNS, .savedState, .binarycookies, Preferences .plist)
- Spotlight and receipt signals used as suppression inputs instead of confidence boosters
- BundleIDMatcher split into strictMatch (orphan-safe) and broadMatch (uninstall-only)
- App inventory expanded with extended discovery roots (System/Applications, Homebrew Caskroom, Setapp)
- SafeDelete validates every path through DeletePolicy before operating
- FileCleaner and AppUninstaller use structured DeleteResult for reporting
- Uninstall execution includes pre-delete (unload agents, remove login items) and post-delete (unregister, refresh LS) phases
- All metadata cleanup steps are non-fatal
- App list loads significantly faster using Spotlight metadata for bundle sizes instead of recursive file walks
- Associated files load lazily on app selection instead of upfront for all apps
- Apple and system apps filtered from the uninstaller list
- Running app detection uses precise matching (full bundle ID and path components) instead of broad substring tokens
- Confidence badge for low-confidence items changed from "Uncertain" to "Review before removing"

### Quality
- 162 tests across 27 suites (up from 72 across 21)

## [1.0.0] - 2026-03-15

### Added
- System Cleaner: scan and remove system caches, browser caches, system logs, crash reports, temporary files, Xcode data, developer caches, Docker data, Homebrew data, .DS_Store files, mail attachments, and Downloads awareness items
- App Leftover Cleanup: detect orphaned files with confidence scoring and show leftovers directly inside scan results
- App Uninstaller: browse installed apps, inspect associated files, uninstall with drag-and-drop, and remove launch agents/daemons
- Large File Finder: scan the home directory for large files above 100 MB, 250 MB, 500 MB, or 1 GB
- Settings: launch at login, Trash vs permanent delete, running-app behavior, temp-file age, safe list, and About links
- Full Disk Access detection with dismissable permission banner
- Keyboard shortcuts: Cmd+1, Cmd+2, Cmd+3, and Cmd+Shift+S
- GitHub Actions CI/CD and DMG packaging on tag pushes

### Changed
- Temporary-file cleanup defaults to 7 days
- Notifications are enabled by default on first launch
- Cleaner categories scan concurrently while preserving stable ordering in results
- Installed-app inventory includes Spotlight-supplemented discovery for non-standard app locations
- Running-app uninstall flow offers a force-quit fallback when a normal terminate request fails

### Quality
- 72 tests across 21 suites
