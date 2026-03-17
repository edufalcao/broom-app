# Broom

A free, open-source macOS utility that helps you reclaim disk space and maintain a clean system. A privacy-respecting alternative to CleanMyMac and CCleaner.

## Features

**System Cleaner** - Scan and remove junk files:
- System and browser caches (Chrome, Firefox, Safari, Arc, Brave, Edge)
- System logs and crash reports
- Temporary files (configurable age threshold, default 7 days)
- Xcode derived data and archives
- Developer caches (npm, pip, Homebrew, CocoaPods, SPM, Yarn)
- Docker data and stale Homebrew versions
- Downloads folder awareness (shown unselected)
- .DS_Store files
- Mail attachments
- Orphaned app leftovers with confidence scoring (suppression-first: only stale, high-confidence results shown)

**App Uninstaller** - Fully uninstall apps:
- Browse all installed apps with icons, sizes, and last-used dates
- Sort by name, size, or last used
- See every associated file across Library directories, grouped by source (user data, preferences, caches, launch items, helpers, receipts, and more)
- Discovers artifacts using name variants (hyphenated, underscored, version-trimmed)
- Unloads launch agents/daemons and cleans up LaunchServices metadata
- Per-file selection — choose exactly what to remove
- Drag-and-drop a .app onto the window to uninstall it
- Running app detection with quit-before-uninstall flow and force-quit fallback

**Large File Finder** - Find oversized files quickly:
- Scan your home directory for files above 100 MB, 250 MB, 500 MB, or 1 GB
- Sort by size, name, or modified date
- Reveal any result in Finder
- Selectively move large files to Trash

**Settings:**
- Launch at login
- Move to Trash (default) or delete permanently
- Skip caches for running apps
- Configurable temp file age threshold
- Toggle developer caches and .DS_Store scanning
- Custom safe list (paths/bundle IDs that are never flagged)

## Safety

- All deletions move files to Trash by default (recoverable)
- Full preview before any deletion
- Confirmation dialogs for all destructive actions
- Hardcoded exclusion list for system-critical files
- Running app detection before cleaning caches
- Orphaned files are unselected by default
- Per-file selection in uninstall previews
- Delete policy validates every path (symlink checks, protected system paths, protected data families)
- Sensitive app data (password managers, VPNs, browsers, AI tools) never surfaced in generic scans

## Privacy

- No telemetry. No analytics. No crash reporting.
- No network access. All operations are local.
- Open source. All behavior is auditable.

## Requirements

- macOS 14.0 (Sonoma) or later
- Full Disk Access recommended for complete scanning (optional)

## Install

### Download
Download the latest DMG from [Releases](../../releases).

### Homebrew (coming soon)
```
brew install --cask broom
```

## Build from Source

```bash
# Install xcodegen
brew install xcodegen

# Clone and build
git clone https://github.com/edufalcao/broom-app.git
cd broom-app
xcodegen generate
open Broom.xcodeproj
```

Build and run with Cmd+R in Xcode, or from the command line:

```bash
xcodebuild -scheme Broom -configuration Debug build
```

Run tests:

```bash
xcodebuild -scheme Broom -configuration Debug test
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+S | Start scan |
| Cmd+1 | Switch to System Cleaner |
| Cmd+2 | Switch to App Uninstaller |
| Cmd+3 | Switch to Large Files |
| Cmd+, | Open Settings |
| Cmd+Q | Quit |

## Architecture

MVVM + service protocol layer. Services handle file-system work behind testable interfaces, and the app uses Swift concurrency throughout the cleaner, uninstaller, and large-file flows. See [docs/engineering/architecture.md](docs/engineering/architecture.md) for details.

## License

MIT - see [LICENSE](LICENSE)
