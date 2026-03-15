# Changelog

All notable changes to Broom will be documented in this file.

## [Unreleased]

## [1.2.1] - 2026-03-15

### Changed
- Settings opens as a native macOS Settings window instead of a modal sheet
- Toolbar gear button uses SettingsLink for standard macOS behavior
- Category drill-in uses NavigationStack for proper push/pop transitions with scroll preservation
- Category rows are Buttons instead of tap gestures for full VoiceOver and keyboard support
- Replaced NotificationCenter communication with type-safe AppRouter observable
- Clean complete screen reflects actual delete method (Trash vs permanent)
- Uninstall confirmation sheet adapts to content height instead of fixed size
- App drop handler uses modern dropDestination API

### Fixed
- Missing @MainActor on UninstallerViewModel causing potential data races
- RelativeDateTimeFormatter allocated on every list row evaluation (now cached)
- Redundant accessibility label on SizeLabel duplicating text content
- Force-unwrapped URL in PermissionChecker.requestFullDiskAccess

### Added
- AppRouter: @Observable class for type-safe cross-component action dispatch
- LargeFileScanning protocol for dependency injection in LargeFilesViewModel
- Smooth fade animations on state transitions in all three main views
- 8 new tests: AppRouter (5), ScanViewModel movedToTrash (2), LargeFilesViewModel DI (1)
- MockLargeFileScanner test infrastructure
- 65 tests across 20 suites

## [1.2.0] - 2026-03-15

### Added
- Large File Finder: new sidebar tab to scan home directory for files > 100 MB
- Docker cleanup: scan Docker VM data and config (new scan category)
- Homebrew cleanup: detect old formula versions and cached downloads (new scan category)
- Dock icon badge showing total junk size after scan
- VoiceOver accessibility labels on all key interactive elements
- Receipt database orphan detection (/var/db/receipts)
- Spotlight metadata orphan detection (NSMetadataQuery)
- Safe List empty state with description
- Settings modal sheet with Done button
- Cmd+3 shortcut for Large Files section
- 57 tests across 19 suites

### Changed
- App Leftovers displayed as a regular category row (not a separate section)
- Confidence badges preserved when orphans convert to category items
- Settings opens as modal sheet blocking main window instead of separate window
- About tab has fixed header with scrollable release notes area

### Fixed
- Sort picker label wrapping in Large Files header
- Settings tab bar clipping at sheet top edge

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
