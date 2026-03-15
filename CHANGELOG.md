# Changelog

All notable changes to Broom will be documented in this file.

## [Unreleased]

## [1.1.0] - 2026-03-15

### Added
- Service protocol layer (`ServiceProtocols.swift`) for dependency injection
- Centralized `AppPreferences` struct injected into services at runtime
- In-app release notes in the About settings tab
- Uninstall confirmation sheet with per-file selection and Trash/permanent toggle
- Launch agent and daemon discovery in app uninstaller
- Running app detection with warning before cleaning caches
- Comprehensive test suite: 14 test files, ~39 tests with mock infrastructure
- Keyboard shortcuts: Cmd+1 (Clean), Cmd+2 (Apps)
- Settings toolbar button in main window

### Changed
- Cleaning settings now actively control scanner behavior (dev caches, .DS_Store, temp file age, delete method)
- App inventory loads associated files upfront so sort-by-size reflects real uninstall footprint
- App uninstaller supports per-file selection in previews
- Sidebar shows inline spinner on the active section during scan/loading
- App list shows relative date when sorted by Last Used
- Category detail shows file paths instead of relative dates
- Category rows show mixed checkbox when partially selected

### Fixed
- Orphan detection integrated into main scan results flow
- Dragged `.app` bundles outside the indexed list now open uninstall preview correctly
- Sidebar selection works correctly (optional binding for macOS List)
- Apps split view maintains visual separation when window is inactive

## [1.0.0] - 2026-03-15

### Added
- System Cleaner: scan and remove system caches, browser caches (Chrome, Firefox, Safari, Arc, Brave, Edge), system logs, crash reports, temporary files, Xcode derived data/archives, developer caches (npm, pip, Homebrew, CocoaPods, SPM, Yarn), .DS_Store files, and mail attachments
- App Leftover Cleanup: detect orphaned files with confidence scoring (high/medium/low)
- App Uninstaller: browse installed apps, view associated files, full uninstall with drag-and-drop
- Settings: launch at login, Trash vs permanent delete, running app skip, temp file age, safe list
- Full Disk Access detection with dismissable permission banner
- Notifications after scan and clean operations
- App icon: minimal broom glyph on teal gradient
- GitHub Actions CI/CD: build on push/PR, release DMG on tag
- DMG packaging scripts and notarization support
