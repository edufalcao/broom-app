# Broom — Product Requirements Document

> **Version:** 1.1.0
> **Author:** Eduardo
> **Date:** 2026-03-16
> **Status:** Implemented (v1.1.0 current)

---

## 1. Overview

### 1.1 What is Broom?

Broom is a free, open-source macOS desktop utility that helps users reclaim disk space and maintain a clean system. It serves as a privacy-respecting, transparent alternative to commercial tools like CleanMyMac and CCleaner.

### 1.2 Vision

A lightweight, trustworthy system cleaner with a standard macOS window, clear previews, and no hidden behavior behind a paywall or data collection.

### 1.3 Target Users

- macOS users who want to free disk space without paying for CleanMyMac ($39.95/yr)
- Privacy-conscious users who distrust CCleaner's data collection practices
- Developers who accumulate Xcode derived data, node_modules caches, etc.
- Power users who want a quick way to uninstall apps cleanly (including leftover files)
- Anyone who wants visibility into what's consuming disk space in Library directories

### 1.4 Non-Goals

- Broom is **not** an antivirus or malware scanner
- Broom does **not** optimize RAM, CPU, or battery (these "optimizers" are typically snake oil)
- Broom does **not** manage arbitrary third-party startup items beyond Broom's own optional launch-at-login toggle
- Broom does **not** touch system-protected files (SIP-protected paths)
- Broom will **never** collect telemetry, analytics, or user data

---

## 2. Core Features

### 2.1 Feature F1: Junk & Cache Cleaning

**Priority:** P0 (MVP)
**Description:** Scan and remove temporary files, caches, and logs that accumulate over time and consume disk space.

#### 2.1.1 Scan Targets

| Category | Paths | Notes |
|----------|-------|-------|
| **System Caches** | `~/Library/Caches/` | Per-app cache directories. Safe to delete — apps regenerate caches on next launch. |
| **Browser Caches — Chrome** | `~/Library/Caches/Google/Chrome/Default/Cache/`, `~/Library/Caches/Google/Chrome/Default/Code Cache/`, `~/Library/Caches/Google/Chrome/Profile */Cache/` | Only `Cache/` and `Code Cache/` subdirs. Never delete the profile root. Multi-profile aware. |
| **Browser Caches — Firefox** | `~/Library/Caches/org.mozilla.firefox/` | Entire directory is safe to clear. |
| **Browser Caches — Safari** | `~/Library/Caches/com.apple.Safari/` | Requires Full Disk Access (TCC-protected). |
| **Browser Caches — Arc** | `~/Library/Caches/company.thebrowser.Browser/` | Chromium-based, same rules as Chrome. |
| **Browser Caches — Brave** | `~/Library/Caches/BraveSoftware/Brave-Browser/Default/Cache/` | Chromium-based. |
| **Browser Caches — Edge** | `~/Library/Caches/com.microsoft.edgemac/` | Chromium-based. |
| **System Logs** | `~/Library/Logs/`, `/Library/Logs/` | Log files accumulate indefinitely. Safe to delete. |
| **Crash Reports** | `~/Library/Logs/DiagnosticReports/` | Old crash reports. Safe to delete. |
| **Temporary Files** | User's `$TMPDIR`, `/tmp/` | OS-managed temp dirs. Only delete files older than 7 days by default (configurable). |
| **Xcode Derived Data** | `~/Library/Developer/Xcode/DerivedData/` | Often 10-50+ GB for active developers. Only shown if directory exists. |
| **Xcode Archives** | `~/Library/Developer/Xcode/Archives/` | Old build archives. Only shown if directory exists. |
| **Swift Package Manager Cache** | `~/Library/Caches/org.swift.swiftpm/` | SPM downloaded packages. |
| **CocoaPods Cache** | `~/Library/Caches/CocoaPods/` | Pod spec cache. |
| **Homebrew Cache** | `~/Library/Caches/Homebrew/` | Downloaded bottles. |
| **npm Cache** | `~/.npm/_cacache/` | npm package cache. |
| **Yarn Cache** | `~/Library/Caches/Yarn/` | Yarn package cache. |
| **pip Cache** | `~/Library/Caches/pip/` | Python package cache. |
| **Mail Attachments** | `~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/` | Downloaded mail attachments. Requires FDA. |
| **Downloads Folder** | `~/Downloads/` | Only shown for awareness (size display). Not auto-selected for deletion — user must explicitly opt in. |
| **.DS_Store Files** | Recursive from `~/` | macOS Finder metadata. ~6-12KB each but thousands accumulate. Skip `.Trash`, `Library`, hidden dirs. |

#### 2.1.2 Scan Behavior

- Scan runs asynchronously using Swift concurrency (`async`/`await` with `TaskGroup`)
- Each category scans in parallel for performance, then results are reassembled into a stable display order
- Progress indicator shows which category is currently being scanned
- Scan results are cached in memory until the user dismisses or re-scans
- Size calculation uses `totalFileAllocatedSizeKey` for accuracy (accounts for sparse files, compression)

#### 2.1.3 Exclusion Rules (Hardcoded Safety)

The following are **never** flagged for deletion, even if found inside scannable directories:

- The app's own bundle identifier directories (`com.broom.app`)
- Active browser profile databases (bookmarks, history, login data)
- Running application caches (detected via `NSWorkspace.shared.runningApplications`)
- System-critical caches:
  - `com.apple.iconservices`
  - `com.apple.dock`
  - `com.apple.Spotlight`
  - `com.apple.bird` (iCloud sync)
  - `com.apple.nsurlsessiond`
  - `CloudKit/`
  - `com.apple.LaunchServices`

#### 2.1.4 User-Defined Exclusions

Users can add paths to a "safe list" in Settings. These paths are never scanned or flagged.

---

### 2.2 Feature F2: App Leftover Cleanup

**Priority:** P0 (MVP)
**Description:** Detect and remove orphaned files left behind after applications have been uninstalled (dragged to Trash).

#### 2.2.1 How It Works

1. **Build an inventory of installed apps:**
   - Enumerate `/Applications/`, `~/Applications/`, and extended discovery roots (System/Applications, Homebrew Caskroom, Setapp) recursively
   - Read `Info.plist` from each `.app` bundle to extract `CFBundleIdentifier`
   - Supplement with `NSMetadataQuery` (Spotlight) for apps in non-standard locations
   - Build an `InstalledAppSnapshot` containing all installed bundle IDs, running bundle IDs, app URLs, and launch item labels

2. **Scan Library directories for orphans:**
   - `~/Library/Application Support/`
   - `~/Library/Caches/`
   - `~/Library/Preferences/`
   - `~/Library/Containers/`
   - `~/Library/Group Containers/`
   - `~/Library/Saved Application State/`
   - `~/Library/WebKit/`
   - `~/Library/HTTPStorages/`

3. **Suppression-first filtering (9 gates):**
   Every candidate must pass all nine checks before being surfaced. This ensures only stale, high-confidence leftovers appear in results:
   1. **Pattern gate:** only entries matching strict patterns (reverse-DNS bundle IDs, `.savedState`, `.binarycookies`, Preferences `.plist`) are considered
   2. **Exclusion list:** built-in rules and user safe list
   3. **Protected data families:** password managers, VPNs, browsers, AI tools, iCloud data, and automation tools are never surfaced (see 2.2.3)
   4. **Installed app match:** strict bundle-ID matching against snapshot
   5. **Running app match:** strict match against running bundle IDs
   6. **Launch item match:** suppress if name matches an active launch item label
   7. **Spotlight/LaunchServices:** suppress if Spotlight still knows about the app
   8. **Size threshold:** entries smaller than 4 KB are suppressed
   9. **Stale-age threshold:** recently modified entries are suppressed (default: 30 days, configurable in Settings)

4. **Present results grouped by inferred app name:**
   - Show all orphan locations for the same app together
   - Show total size per orphaned app
   - Default: **unselected** (user must explicitly check items to delete)

#### 2.2.2 Orphan Confidence Scoring

Each orphan gets a confidence score to help users decide:

| Confidence | Criteria | UI Treatment |
|------------|----------|--------------|
| **High** | Saved Application State + bundle-ID pattern, or receipt evidence | Show with clear "safe to remove" indicator |
| **Medium** | Bundle-ID pattern match | Show with neutral indicator |
| **Low** | Weak evidence only | Show with warning indicator, explain uncertainty |

#### 2.2.3 Protected Data Families

Leftovers belonging to these app families are **never** surfaced in orphan scan results, regardless of other signals. This prevents accidental deletion of sensitive data:

| Family | Examples |
|--------|----------|
| **Password managers** | 1Password, LastPass, Bitwarden, KeePassXC, Dashlane |
| **VPN / proxy tools** | Mullvad, NordVPN, ExpressVPN, WireGuard, Tailscale |
| **Browsers** | Safari, Chrome, Firefox, Arc, Brave, Edge |
| **AI tools** | ChatGPT, Claude, Copilot, LM Studio, Ollama |
| **iCloud-synced data** | iCloud, MobileSync, CloudDaemon |
| **Automation tools** | Keyboard Maestro, Alfred, Raycast, Hammerspoon |

These families are defined in `ProtectedDataPolicy` and matched by both bundle ID prefix and path component.

---

### 2.3 Feature F3: App Uninstaller

**Priority:** P0 (MVP)
**Description:** Fully uninstall applications by removing the `.app` bundle and all associated files across Library directories, in a single action.

#### 2.3.1 How It Works

1. **App List View:**
   - Show all installed apps from `/Applications/`, `~/Applications/`, and Spotlight-supplemented non-standard locations
   - Display for each: app icon, name, version, bundle size, total size (including Library files)
   - Sort options: name, size (total), last used date
   - Search/filter bar
   - Distinguish between user-installed and system apps

2. **App Detail / Uninstall Preview:**
   - When user selects an app, the `UninstallArtifactPlanner` discovers all associated files using 11 artifact providers:
     - The `.app` bundle itself
     - `~/Library/Application Support/<bundleID or appName>/`
     - `~/Library/Caches/<bundleID or appName>/`
     - `~/Library/Preferences/<bundleID>.plist` (including ByHost variants)
     - `~/Library/Containers/<bundleID>/`
     - `~/Library/Group Containers/*<bundleID>*/`
     - `~/Library/Saved Application State/<bundleID>.savedState/`
     - `~/Library/WebKit/<bundleID>/`, `~/Library/Cookies/<bundleID>.binarycookies`, `~/Library/HTTPStorages/<bundleID>/`
     - `~/Library/Logs/<bundleID or appName>/` and matching DiagnosticReports
     - LaunchAgents/LaunchDaemons (`~/Library/LaunchAgents/`, `/Library/LaunchAgents/`, `/Library/LaunchDaemons/`)
     - Privileged helper tools (`/Library/PrivilegedHelperTools/`)
     - Package receipts (`/var/db/receipts/`)
     - Application Scripts (`~/Library/Application Scripts/<bundleID>/`)
   - App name variants (no-space, hyphenated, underscored, lowercase, version/channel trimmed) are generated to find artifacts stored under non-standard names
   - Results are grouped by artifact source with section headers in the UI
   - Show individual sizes for each location
   - Show total size that will be freed
   - All items selected by default (user can uncheck to keep specific files)

3. **Uninstall Process:**
   - Confirm with dialog: "Uninstall AppName? This will remove X files totaling Y MB."
   - If the app is currently running: prompt to quit it first (offer to force-quit)
   - **Pre-delete:** unload matching launch agents/daemons and remove login items
   - Move all selected files to Trash (not permanent delete)
   - **Post-delete:** unregister the app from LaunchServices and refresh the LS database
   - Show progress bar during removal (with phase reporting)
   - Show summary: "Freed X MB. Files moved to Trash."
   - All metadata cleanup steps are non-fatal — failures are logged but do not block the uninstall

4. **Protected Apps (cannot uninstall):**
   - System apps in `/System/Applications/` — hidden from the list entirely
   - Apple apps that shipped with macOS (`Safari.app`, `Mail.app`, etc.) — shown but disabled with explanation
   - Broom itself — disabled with humorous tooltip ("I can't uninstall myself!")

#### 2.3.2 File Discovery Strategy

The `UninstallArtifactPlanner` finds all files associated with an app using bundle ID matching and name variant generation:

```
Strategy 1: Bundle ID matching
  - Read CFBundleIdentifier from the app's Info.plist
  - Search all 11 artifact locations for entries matching the bundle ID

Strategy 2: Name variant matching
  - Generate variants from the app's display name:
    - Original, no-space, hyphenated, underscored, and lowercase forms
    - Version and channel suffixes (Beta, Canary, Dev, etc.) are trimmed
  - Search Application Support, Caches, and Logs for variant matches

Strategy 3: Glob matching
  - For directories with mixed content (Group Containers, ByHost, receipts, helpers),
    enumerate entries and match filenames containing the bundle ID

Strategy 4: LaunchAgent/LaunchDaemon discovery
  - Enumerate plist files in LaunchAgents and LaunchDaemons directories
  - Match filenames against the app's bundle ID
```

#### 2.3.3 Drag-and-Drop Uninstall

- Users can drag a `.app` file from Finder onto the Broom app window
- The Dock icon can also accept `.app` drops and route the user into the uninstall flow
- This triggers the uninstall preview for that specific app
- Provides a quick, intuitive uninstall workflow similar to AppCleaner

---

### 2.4 Feature F4: Large File Finder

**Priority:** P1
**Description:** Scan the user's home directory for oversized files that are worth reviewing separately from cleaner categories.

#### 2.4.1 Scan Behavior

- Scan `~/` recursively for regular files above a configurable threshold
- Supported thresholds: 100 MB, 250 MB, 500 MB, and 1 GB
- Skip known noise directories such as `~/Library/`, `~/Library/Caches/`, `~/.Trash/`, `.git/`, `node_modules/`, `.build/`, `Pods/`, `DerivedData/`, and `.cache/`
- Show results as a flat list with name, directory, size, and modified date
- Default sort: size descending
- Alternate sorts: name and modified date
- Files start **unselected**; the user explicitly chooses what to move to Trash
- Each result can be revealed in Finder before cleanup

#### 2.4.2 Cleanup Behavior

- Large-file cleanup always moves selected files to Trash
- This flow is intentionally separate from the system cleaner so users can review large personal files without mixing them into cache-oriented categories
- The final summary shows bytes freed and number of files moved

---

## 3. User Interface

### 3.1 Application Window

- Standard macOS desktop app with Dock icon
- Single main window with sidebar navigation
- Three main sections accessible via sidebar: **System Cleaner**, **App Uninstaller**, and **Large File Finder**
- Default window size: 750x520, minimum: 650x450
- Toolbar contains: settings gear button, window title
- Standard window chrome (close, minimize, zoom)
- After a scan completes, the Dock icon shows the current junk total as a badge until the result is cleaned or reset

### 3.2 Main Window Layout

The app uses a `NavigationSplitView` with a two-column layout: a narrow sidebar for section navigation and a main content area.

#### 3.2.1 System Cleaner States

```
┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 1: IDLE                               │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │  ┌─────────────────────────────────────────┐ │ │
│  │          │  │  │      [!] Full Disk Access                │ │ │
│  │ 📦 Apps  │  │  │      required for full scan              │ │ │
│  │          │  │  │      [Grant Access]                      │ │ │
│  │          │  │  └─────────────────────────────────────────┘ │ │
│  │          │  │                                               │ │
│  │          │  │    ┌───────────────────────────────┐          │ │
│  │          │  │    │       🔍 Scan System           │          │ │
│  │          │  │    └───────────────────────────────┘          │ │
│  │          │  │                                               │ │
│  │          │  │  Last scan: 2 days ago                        │ │
│  │ ─────── │  │                                               │ │
│  │ ⚙️ Set  │  │                                               │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 2: SCANNING                           │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │  Scanning system caches...                   │ │
│  │          │  │  ████████████░░░░░░░░  60%                   │ │
│  │ 📦 Apps  │  │                                               │ │
│  │          │  │  Found 3.2 GB so far                          │ │
│  │          │  │                                               │ │
│  │          │  │  [Cancel]                                     │ │
│  │          │  │                                               │ │
│  │ ─────── │  │                                               │ │
│  │ ⚙️ Set  │  │                                               │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 3: SCAN RESULTS                       │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │  Found 8.3 GB of junk                        │ │
│  │          │  │  Scanned in 4.2s                              │ │
│  │ 📦 Apps  │  │                                               │ │
│  │          │  │  ☑ System Caches      2.1 GB  >              │ │
│  │          │  │  ☑ Browser Caches     1.8 GB  >              │ │
│  │          │  │  ☑ System Logs        340 MB  >              │ │
│  │          │  │  ☑ Xcode Data         3.8 GB  >              │ │
│  │          │  │  ☑ Temp Files         180 MB  >              │ │
│  │          │  │  ☑ .DS_Store Files    12 MB   >              │ │
│  │          │  │  ───────────────────────────────              │ │
│  │          │  │  ☐ App Leftovers      890 MB  >              │ │
│  │          │  │                                               │ │
│  │          │  │  Selected: 8.3 GB                             │ │
│  │          │  │  ┌─────────────────────────┐                  │ │
│  │          │  │  │    🧹 Clean Selected     │                  │ │
│  │ ─────── │  │  └─────────────────────────┘                  │ │
│  │ ⚙️ Set  │  │  [↻ Re-scan]                                 │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 4: CATEGORY DETAIL (drilldown)        │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │  ← System Caches (2.1 GB)                    │ │
│  │          │  │                                               │ │
│  │ 📦 Apps  │  │  ☑ Select All                                │ │
│  │          │  │                                               │ │
│  │          │  │  ☑ com.spotify.client     680 MB             │ │
│  │          │  │  ☑ com.google.Chrome      420 MB             │ │
│  │          │  │  ☑ org.mozilla.firefox    310 MB             │ │
│  │          │  │  ☑ com.docker.docker      280 MB             │ │
│  │          │  │  ☐ com.apple.Safari       190 MB             │ │
│  │          │  │  ☑ com.microsoft.VSCode   140 MB             │ │
│  │          │  │  ... (scrollable)                             │ │
│  │          │  │                                               │ │
│  │ ─────── │  │  Selected: 1.83 GB of 2.1 GB                 │ │
│  │ ⚙️ Set  │  │                                               │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 5: CLEANING                           │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │  Cleaning system caches...                   │ │
│  │          │  │  ████████████████░░░░  78%                   │ │
│  │ 📦 Apps  │  │                                               │ │
│  │          │  │  42 of 54 items cleaned                       │ │
│  │          │  │  5.2 GB freed                                 │ │
│  │          │  │                                               │ │
│  │ ─────── │  │                                               │ │
│  │ ⚙️ Set  │  │                                               │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  State 6: DONE                               │ │
│  │          │  │                                               │ │
│  │ 🔍 Clean │  │         ✓ All clean!                         │ │
│  │          │  │                                               │ │
│  │ 📦 Apps  │  │     Freed 8.1 GB of disk space               │ │
│  │          │  │     54 items moved to Trash                   │ │
│  │          │  │                                               │ │
│  │          │  │  ┌─────────────────────────┐                  │ │
│  │          │  │  │    ↻ Scan Again          │                  │ │
│  │ ─────── │  │  └─────────────────────────┘                  │ │
│  │ ⚙️ Set  │  │                                               │ │
│  └──────────┘  └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.2.2 App Uninstaller View

Accessed via the "Apps" sidebar item. Displayed in the main content area using a nested split view.

```
┌──────────────────────────────────────────────────────────────────┐
│  Broom                                                ─  □  ✕   │
│  ────────────────────────────────────────────────────────────── │
│  ┌──────────┐  ┌──────────────────────────────────────────────┐ │
│  │ SIDEBAR  │  │  🔍 Search apps...                           │ │
│  │          │  │  ──────────────────────────────────────────── │ │
│  │ 🔍 Clean │  │  Sort: [Name ▾]  [Size ▾]  [Last Used ▾]    │ │
│  │          │  │  ──────────────────────────────────────────── │ │
│  │ 📦 Apps  │  │                                               │ │
│  │          │  │  ┌──────────────────┐ ┌─────────────────────┐ │ │
│  │          │  │  │ App List         │ │ Detail               │ │ │
│  │          │  │  │                  │ │                       │ │ │
│  │          │  │  │ 🎵 Spotify  420M│ │ Spotify               │ │ │
│  │          │  │  │ 🐳 Docker  3.2G │ │ Version 1.2.25        │ │ │
│  │          │  │  │ 💬 Slack   180M │ │ Last used: 3 days ago │ │ │
│  │          │  │  │ 📝 Notion   95M │ │                       │ │ │
│  │          │  │  │ 🎮 Steam  1.8G  │ │ Files:                │ │ │
│  │          │  │  │ ...             │ │ ☑ Spotify.app  380 MB│ │ │
│  │          │  │  │                  │ │ ☑ App Support   28 MB│ │ │
│  │          │  │  │                  │ │ ☑ Caches        11 MB│ │ │
│  │          │  │  │                  │ │ ☑ Preferences  4 KB  │ │ │
│  │          │  │  │                  │ │ ☑ Saved State  12 KB │ │ │
│  │          │  │  │                  │ │                       │ │ │
│  │          │  │  │                  │ │ Total: 420.2 MB       │ │ │
│  │          │  │  │                  │ │                       │ │ │
│  │          │  │  │                  │ │ ┌────────────────────┐│ │ │
│  │          │  │  │                  │ │ │  🗑️ Uninstall     ││ │ │
│  │ ─────── │  │  │                  │ │ └────────────────────┘│ │ │
│  │ ⚙️ Set  │  │  └──────────────────┘ └─────────────────────┘ │ │
│  └──────────┘  │  Drop a .app here to uninstall it             │ │
│                 └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### 3.3 Settings View

Accessed via the toolbar/gear affordance or `Cmd+,`. Implemented as a standard macOS Settings window for MVP; an inline/sidebar shortcut is optional polish.

**General Tab:**
- Launch at login (toggle, uses `SMAppService`)
- Show scan results notification (toggle, enabled by default)

**Cleaning Tab:**
- Default action: Move to Trash / Delete permanently (picker, default: Trash)
- Skip caches for currently running apps (toggle, default: on)
- Minimum file age for temp files (picker, default: 7 days)
- Show developer caches (Xcode, npm, pip, etc.) (toggle, default: on)

**Safe List Tab:**
- List of paths/bundle IDs that will never be flagged
- Add/remove buttons
- Stored as JSON in `~/Library/Application Support/Broom/safelist.json`

**About Tab:**
- Version and build number
- GitHub link
- License (MIT)
- Credits and in-app release notes

### 3.4 Notifications

- After a background scan (if enabled): "Broom found X GB of junk files. Click to review."
- After cleaning: "Freed X GB of disk space."
- Uses `UserNotifications` framework

### 3.5 Drag-and-Drop

- The main window (specifically the App Uninstaller content area) accepts `.app` file drops
- When a `.app` is dropped, the uninstaller view activates with that app pre-selected
- The Dock icon also accepts `.app` file drops, switching to the uninstaller view on drop
- Uses `.dropDestination(for: URL.self)` in SwiftUI for the window, and `NSApplicationDelegate` for Dock drops

---

## 4. Technical Requirements

### 4.1 Platform & Framework

| Requirement | Value |
|-------------|-------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Minimum macOS** | 14.0 (Sonoma) |
| **Architecture** | Universal (arm64 + x86_64) |
| **Window Style** | Standard desktop app with Dock icon and main window |
| **Sandboxing** | Disabled (required for file system access) |
| **Hardened Runtime** | Enabled (required for notarization) |
| **App Store** | Not possible (non-sandboxed) |

### 4.2 Permissions

| Permission | Why | How |
|------------|-----|-----|
| **Full Disk Access** | Access Safari caches, Mail attachments, some system dirs | User must grant in System Settings. App detects status and shows banner. |
| **File System Access** | Read/write/delete files in `~/Library/`, `/tmp/`, etc. | Automatic for non-sandboxed apps. |
| **Automation** | Force-quit apps during uninstall | Optional. Uses `NSRunningApplication.terminate()` which doesn't require entitlement. |

### 4.3 Performance Targets

| Metric | Target |
|--------|--------|
| **Full scan time** | < 10 seconds on SSD |
| **Memory usage (idle)** | < 20 MB |
| **Memory usage (scanning)** | < 100 MB |
| **App launch to main window** | < 1 second |
| **Binary size** | < 10 MB |

### 4.4 Data Storage

- **Preferences:** `UserDefaults` (stored in `~/Library/Preferences/com.broom.app.plist`)
- **Safe list:** JSON file in `~/Library/Application Support/Broom/safelist.json`
- **Scan history:** Optional. Last scan date stored in `UserDefaults`
- **No database.** No Core Data, no SQLite. The app is stateless by design.

---

## 5. Safety & Risk Mitigation

### 5.1 Deletion Safety

This is the most critical aspect of the app. A cleaner that deletes the wrong file is worse than no cleaner at all.

| Layer | Mechanism | Description |
|-------|-----------|-------------|
| **1** | Preview before delete | Full scan results shown before any deletion occurs |
| **2** | Move to Trash (default) | All deletions use `FileManager.trashItem()`. User can recover from Trash. |
| **3** | Confirmation dialog | `NSAlert` before every clean/uninstall action |
| **4** | Hardcoded exclusion list | System-critical paths are never flagged (see §2.1.3) |
| **5** | Running app detection | Warn if cleaning caches for apps that are currently running |
| **6** | Orphan confidence scoring | Low-confidence orphans shown with warning (see §2.2.2) |
| **7** | Orphans unselected by default | User must explicitly opt-in to orphan removal |
| **8** | Dry-run logging | Every path scheduled for deletion is logged via `os.Logger` before deletion |
| **9** | User safe list | Custom exclusions that persist across scans |
| **10** | Protected app list | System and Apple apps cannot be uninstalled |
| **11** | Delete policy validation | `DeletePolicy` enforces path safety, symlink checks, and protected-data rules at the operation boundary |
| **12** | Protected data families | Sensitive app data (password managers, VPNs, browsers, AI tools) never surfaced in generic scans (see §2.2.3) |
| **13** | Stale-age threshold | Recently modified items excluded from orphan results (default 30 days, configurable) |

### 5.2 Error Handling

- Permission denied → skip item, continue with others, report at end
- File in use → skip item, note in results
- Path doesn't exist (race condition) → skip silently
- Partial failure → report what succeeded and what failed
- Never crash on file system errors

### 5.3 Privacy

- **No telemetry.** No analytics. No crash reporting to external services.
- **No network access in the MVP.** The app never makes network requests during core scan/clean flows.
- **No data leaves the machine.** All operations are strictly local.
- **Open source.** All behavior is auditable.

---

## 6. Distribution & Packaging

### 6.1 Distribution Channels

| Channel | Priority | Notes |
|---------|----------|-------|
| **GitHub Releases** | P0 | DMG download from releases page |
| **Homebrew Cask** | P1 | `brew install --cask broom` via custom tap |
| **Direct download from website** | P2 | Optional landing page |

### 6.2 Build & Release Pipeline

- **CI:** GitHub Actions
- **Build:** `xcodebuild` with universal binary (arm64 + x86_64)
- **Signing:** Apple Developer certificate (optional; can distribute unsigned for personal use)
- **Notarization:** `xcrun notarytool` (requires Apple Developer account, $99/yr)
- **DMG Creation:** `create-dmg` (open source tool)
- **Release trigger:** Git tag push (`v*`)

### 6.3 Update Mechanism

- **Post-MVP option:** Sparkle framework (open source, standard for non-App Store mac apps)
- Not required for v1.0/MVP; the initial release should build with zero third-party runtime dependencies
- If added later: check for updates on launch (configurable), allow manual checks in Settings, and install updates in-place

---

## 7. Open Source

### 7.1 License

MIT License — maximally permissive, encourages adoption and contribution.

### 7.2 Repository Structure

```
broom-app/
├── Broom/                    # Xcode project source
│   ├── BroomApp.swift
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/               # MainWindow, Cleaner/, Uninstaller/, LargeFiles/, Settings/, Components/
│   ├── Services/
│   ├── Utilities/
│   └── Assets.xcassets/
├── BroomTests/               # Unit tests
├── docs/                     # Documentation (this file, architecture, etc.)
├── scripts/                  # Build, package, release scripts
├── .github/
│   ├── workflows/            # CI/CD
│   └── ISSUE_TEMPLATE/       # Bug report, feature request templates
├── LICENSE                   # MIT
├── README.md                 # Project overview, screenshots, install instructions
├── CONTRIBUTING.md           # How to contribute
└── CHANGELOG.md              # Version history
```

### 7.3 Contribution Guidelines

- Issues for bug reports and feature requests
- Pull requests welcome with tests
- Code style: Swift standard conventions, SwiftLint enforced
- All PRs require one review

---

## 8. Future Roadmap

These features are planned for future versions.

| Feature | Version | Description |
|---------|---------|-------------|
| **Duplicate File Finder** | v1.2 | Content-hash-based duplicate detection |
| **Scheduled Cleaning** | v1.2 | Run scans on a schedule (weekly/monthly) with notification |
| **Auto-Update (Sparkle)** | v1.2 | In-app update checking and installation |
| **Disk Usage Visualization** | v1.2 | Treemap or sunburst chart of disk usage |
| **CLI Interface** | v1.2 | `broom scan`, `broom clean` for terminal users |
| **Localization** | v1.2 | Multi-language support |

---

## 9. Success Metrics

Since this is an open-source passion project, success is measured by:

- **Usefulness:** Does it reliably free significant disk space?
- **Safety:** Zero incidents of accidental data loss
- **Adoption:** GitHub stars, forks, and contributors
- **Simplicity:** App stays lightweight and focused
- **Trust:** Users feel confident using it because behavior is transparent and predictable

---

## 10. Glossary

| Term | Definition |
|------|------------|
| **Bundle ID** | Reverse-domain identifier for a macOS app (e.g., `com.spotify.client`) |
| **FDA** | Full Disk Access — a macOS privacy permission |
| **SIP** | System Integrity Protection — macOS security that protects system files |
| **TCC** | Transparency, Consent, and Control — macOS framework managing app permissions |
| **Orphan** | Files left behind in Library directories after an app has been uninstalled |
| **Safe list** | User-defined list of paths/bundle IDs that Broom will never flag |
| **Sparkle** | Open-source framework for auto-updating macOS apps outside the App Store |
