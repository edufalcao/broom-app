# Broom

A free, open-source macOS utility that helps you reclaim disk space and maintain a clean system. A privacy-respecting alternative to CleanMyMac and CCleaner.

## Features

**System Cleaner** - Scan and remove junk files:
- System and browser caches (Chrome, Firefox, Safari, Arc, Brave, Edge)
- System logs and crash reports
- Temporary files
- Xcode derived data and archives
- Developer caches (npm, pip, Homebrew, CocoaPods, SPM, Yarn)
- .DS_Store files
- Mail attachments

**App Leftover Cleanup** - Detect orphaned files left behind by uninstalled apps, with confidence scoring to help you decide what's safe to remove.

**App Uninstaller** - Fully uninstall apps by removing the .app bundle and all associated files across Library directories in a single action. Supports drag-and-drop.

## Safety

- All deletions move files to Trash by default (recoverable)
- Full preview before any deletion
- Confirmation dialogs for all destructive actions
- Hardcoded exclusion list for system-critical files
- Running app detection
- Orphaned files are unselected by default

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
git clone https://github.com/your-username/broom-app.git
cd broom-app
xcodegen generate
open Broom.xcodeproj
```

Build and run with Cmd+R in Xcode, or from the command line:

```bash
xcodebuild -scheme Broom -configuration Debug build
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+S | Start scan |
| Cmd+, | Open Settings |
| Cmd+Q | Quit |

## License

MIT - see [LICENSE](LICENSE)
