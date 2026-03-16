# Changelog

All notable changes to Broom will be documented in this file.

## [Unreleased]

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
