# Changelog

All notable changes to Broom will be documented in this file.

## [Unreleased]

## [1.1.0] - 2026-03-15

### Added
- In-app 1.1.0 release notes in the About settings tab
- Automated coverage for scanner, orphan detection, settings, cleaning, inventory, and uninstall flows

### Changed
- Cleaning settings now control developer-cache scanning, .DS_Store scanning, temp-file age filtering, and delete behavior
- App uninstall previews now support per-file selection and Trash versus permanent-delete handling
- App inventory sizing now includes associated files so sort-by-size reflects the real uninstall footprint

### Fixed
- Orphaned app leftovers are now detected as part of the main scan results flow
- Dragged `.app` bundles outside the indexed app list now open an uninstall preview correctly
- The Apps split view keeps the sidebar, app list, and detail pane visually separated when the window is inactive
