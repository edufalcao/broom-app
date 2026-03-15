# Broom — Technical Architecture

> **Version:** 1.0.0-draft
> **Date:** 2026-03-15

---

## 1. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        SwiftUI Layer                         │
│                                                              │
│  MainWindow ──── CleanerView ──── ScanResultsView            │
│  UninstallerView ──── AppDetailView ──── SettingsView        │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                      ViewModel Layer                         │
│                                                              │
│  ScanViewModel ──── UninstallerViewModel ──── SettingsViewModel │
│                                                              │
│  State machines driving UI. @Observable classes.             │
│  No file system access — delegates to services.             │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                       Service Layer                          │
│                                                              │
│  FileScanner ──── FileCleaner ──── AppInventory             │
│  OrphanDetector ──── AppUninstaller ──── PermissionChecker  │
│                                                              │
│  Stateful services are Swift actors. Helpers use static APIs. │
│  File system operations stay outside the view layer.         │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                      Foundation Layer                        │
│                                                              │
│  Constants ──── SizeFormatter ──── Logger ──── SafeDelete   │
│  ExclusionList ──── BundleIDMatcher                         │
│                                                              │
│  Stateless utilities. Pure functions where possible.        │
└──────────────────────────────────────────────────────────────┘
```

**Why MVVM + Service Layer?**
- MVVM is the standard SwiftUI pattern — community resources and tutorials are abundant
- The service layer separates file system operations from business logic
- Services are `actor`-typed, making concurrency safe without manual locking
- ViewModels are the only connection between views and services
- This layering makes unit testing straightforward: mock services, test ViewModels

---

## 2. Project Structure

```
Broom/
├── BroomApp.swift                          # @main entry point
├── Info.plist                              # Version, bundle ID
├── Broom.entitlements                      # app-sandbox=false
├── Assets.xcassets/                        # App icon, accent color
│
├── Models/
│   ├── CleanableItem.swift                 # Single file/directory that can be cleaned
│   ├── CleanCategory.swift                 # Grouping of cleanable items (e.g., "System Caches")
│   ├── ScanResult.swift                    # Full scan output with all categories
│   ├── OrphanedApp.swift                   # Detected orphan with all its locations
│   ├── InstalledApp.swift                  # Represents an installed application
│   └── CleanReport.swift                   # Post-clean summary (freed bytes, errors)
│
├── ViewModels/
│   ├── ScanViewModel.swift                 # Drives scan/clean flow (idle→scanning→results→cleaning→done)
│   ├── UninstallerViewModel.swift          # Drives the app uninstaller section
│   └── SettingsViewModel.swift             # Manages preferences and safe list
│
├── Views/
│   ├── MainWindow.swift                    # Top-level NavigationSplitView with inline sidebar content
│   │
│   ├── Cleaner/
│   │   ├── CleanerView.swift               # Main cleaner content, state router
│   │   ├── IdleView.swift                  # Start scan button, last scan info
│   │   ├── ScanningView.swift              # Progress indicator during scan
│   │   ├── ScanResultsView.swift           # Category list with sizes and toggles
│   │   ├── CategoryDetailView.swift        # Drilldown into a single category
│   │   ├── CleanProgressView.swift         # Progress bar during clean operation
│   │   └── CleanDoneView.swift             # Summary after clean completes
│   │
│   ├── Uninstaller/
│   │   ├── UninstallerView.swift           # App uninstaller content (nested split view)
│   │   ├── AppListView.swift               # Left panel: list of installed apps
│   │   ├── AppRowView.swift                # Single app row in the list
│   │   ├── AppDetailView.swift             # Right panel: app files breakdown
│   │   └── UninstallConfirmView.swift      # Confirmation dialog before uninstall
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift              # TabView with General, Cleaning, Safe List, About
│   │   ├── GeneralSettingsView.swift       # Launch at login, notifications
│   │   ├── CleaningSettingsView.swift      # Trash vs delete, running app behavior
│   │   ├── SafeListSettingsView.swift      # Manage exclusion paths
│   │   └── AboutSettingsView.swift         # Version, links, credits
│   │
│   └── Components/
│       ├── CategoryRowView.swift           # Reusable: icon + name + size + chevron + toggle
│       ├── SizeLabel.swift                 # Formatted byte count display
│       ├── PermissionBanner.swift          # FDA not granted warning
│       ├── ConfidenceBadge.swift           # High/Medium/Low confidence indicator
│       ├── AppIconView.swift               # Loads app icon from bundle
│       └── EmptyStateView.swift            # "No junk found" / "No orphans" states
│
├── Services/
│   ├── FileScanner.swift                   # Scans all target directories, computes sizes
│   ├── FileCleaner.swift                   # Moves files to Trash or deletes permanently
│   ├── AppInventory.swift                  # Enumerates installed apps and bundle IDs
│   ├── OrphanDetector.swift                # Detects orphaned Library files
│   ├── AppUninstaller.swift                # Removes app bundle + all associated files
│   ├── PermissionChecker.swift             # Checks Full Disk Access status
│   └── RunningAppDetector.swift            # Detects running apps via NSWorkspace
│
├── Utilities/
│   ├── Constants.swift                     # All scan target paths, protected prefixes
│   ├── SizeFormatter.swift                 # ByteCountFormatter wrapper
│   ├── BundleIDMatcher.swift               # Logic for matching bundle IDs to directory names
│   ├── ExclusionList.swift                 # Manages hardcoded + user-defined exclusions
│   ├── SafeDelete.swift                    # trashItem wrapper with error handling
│   ├── Logger.swift                        # os.Logger wrapper
│   └── AppIconLoader.swift                 # Extracts app icons from .app bundles
│
└── Resources/
    └── Localizable.strings                 # (future) Localization
```

---

## 3. Data Models

### 3.1 CleanableItem

Represents a single file or directory that the user can choose to clean.

```swift
struct CleanableItem: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String              // Display name (last path component)
    let size: Int64               // Size in bytes (allocated, not logical)
    let modifiedDate: Date        // Last modification date
    var isSelected: Bool          // Whether user has checked this for cleaning

    // Computed
    var isDirectory: Bool { path.hasDirectoryPath }
    var formattedSize: String { SizeFormatter.format(size) }
}
```

### 3.2 CleanCategory

Groups related cleanable items under a named category.

```swift
struct CleanCategory: Identifiable {
    let id: UUID
    let name: String              // "System Caches", "Browser Caches", etc.
    let icon: String              // SF Symbol name
    let description: String       // Brief explanation for the user
    var items: [CleanableItem]
    var isSelected: Bool          // Master toggle for the whole category
    var defaultSelected: Bool     // Whether items start selected (false for orphans)

    // Computed
    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var itemCount: Int { items.count }
    var selectedCount: Int { items.filter(\.isSelected).count }
}
```

### 3.3 ScanResult

The output of a full system scan.

```swift
struct ScanResult {
    let categories: [CleanCategory]
    let orphanedApps: [OrphanedApp]
    let scanDuration: TimeInterval
    let scanDate: Date

    // Computed
    var totalSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize } +
        orphanedApps.reduce(0) { $0 + $1.totalSize }
    }

    var selectedSize: Int64 {
        categories.reduce(0) { $0 + $1.selectedSize } +
        orphanedApps.reduce(0) { $0 + $1.selectedSize }
    }

    var totalItems: Int {
        categories.reduce(0) { $0 + $1.itemCount } +
        orphanedApps.reduce(0) { $0 + $1.locationCount }
    }
}
```

### 3.4 OrphanedApp

An application that has been uninstalled but left files behind.

```swift
struct OrphanedApp: Identifiable {
    let id: UUID
    let appName: String                   // Inferred display name
    let bundleIdentifier: String?         // If determinable from directory name
    let confidence: OrphanConfidence      // How confident we are this is truly orphaned
    var locations: [CleanableItem]        // All orphan files for this app

    var totalSize: Int64 { locations.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { locations.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var locationCount: Int { locations.count }
    var selectedCount: Int { locations.filter(\.isSelected).count }
    var isSelected: Bool { !locations.isEmpty && selectedCount == locationCount }
}

enum OrphanConfidence: String, CaseIterable {
    case high    // Exact bundle ID match, app confirmed not installed
    case medium  // Pattern match, likely orphaned
    case low     // Name-only match, could be a false positive
}
```

### 3.5 InstalledApp

Represents an application installed on the system, used by the Uninstaller.

```swift
struct InstalledApp: Identifiable, Hashable {
    let id: UUID
    let name: String                      // CFBundleDisplayName or CFBundleName
    let bundleIdentifier: String          // CFBundleIdentifier
    let version: String                   // CFBundleShortVersionString
    let bundlePath: URL                   // Path to the .app bundle
    let bundleSize: Int64                 // Size of the .app bundle itself
    let icon: NSImage?                    // App icon loaded from bundle
    let isSystemApp: Bool                 // Located in /System/Applications/
    let isAppleApp: Bool                  // Bundle ID starts with com.apple.
    var associatedFiles: [CleanableItem]  // All files in ~/Library/* for this app
    var lastUsedDate: Date?               // From Spotlight metadata

    // Computed
    var totalSize: Int64 { bundleSize + associatedFiles.reduce(0) { $0 + $1.size } }
    var isProtected: Bool { isSystemApp || isAppleApp }
    var formattedTotalSize: String { SizeFormatter.format(totalSize) }
}
```

### 3.6 CleanReport

Summary of a completed clean operation.

```swift
struct CleanReport {
    let freedBytes: Int64
    let itemsCleaned: Int
    let itemsFailed: Int
    let errors: [CleanError]
    let duration: TimeInterval

    struct CleanError {
        let path: URL
        let reason: String
    }
}
```

---

## 4. Service Layer Detail

### 4.1 FileScanner

The core scanning engine. Implemented as a Swift `actor` for thread safety.

```
FileScanner (actor)
├── scanAll() -> AsyncStream<ScanProgress>
│   ├── Reports category-by-category progress
│   ├── Uses TaskGroup for parallel category scanning
│   └── Finishes with .complete(ScanResult)
│
├── scanSystemCaches() async -> CleanCategory
│   ├── Enumerates ~/Library/Caches/ top-level directories
│   ├── Computes size of each subdirectory
│   └── Filters out excluded entries
│
├── scanBrowserCaches() async -> CleanCategory
│   ├── Checks each browser's known cache path
│   ├── Only includes Cache/ and Code Cache/ for Chromium browsers
│   └── Groups all browsers under one category
│
├── scanLogs() async -> CleanCategory
│   ├── Scans ~/Library/Logs/ and /Library/Logs/
│   └── Includes ~/Library/Logs/DiagnosticReports/
│
├── scanTempFiles() async -> CleanCategory
│   ├── Scans $TMPDIR and /tmp/
│   ├── Only includes files older than configurable threshold (default 24h)
│   └── Skips files owned by root
│
├── scanXcode() async -> CleanCategory?
│   ├── Returns nil if Xcode not installed
│   ├── Scans DerivedData and Archives
│   └── Shows per-project breakdown in DerivedData
│
├── scanDeveloperCaches() async -> CleanCategory
│   ├── SPM, CocoaPods, Homebrew, npm, Yarn, pip caches
│   └── Only includes those that exist on disk
│
├── scanDSStores() async -> CleanCategory
│   ├── Recursive enumeration from $HOME
│   ├── Skips .Trash, Library, hidden directories
│   └── Collects all .DS_Store files
│
├── scanMailAttachments() async -> CleanCategory?
│   ├── Returns nil if FDA not granted
│   └── Scans Mail Downloads directory
│
└── directorySize(at: URL) -> Int64
    ├── Uses FileManager.enumerator for memory efficiency
    ├── Reads totalFileAllocatedSizeKey (accurate for APFS)
    └── Handles permission errors gracefully (returns 0 for inaccessible)
```

**Performance considerations:**
- `FileManager.enumerator` is used over `contentsOfDirectory` for large trees — it doesn't load all URLs into memory at once
- Size calculation reads `totalFileAllocatedSizeKey` which accounts for APFS clones, sparse files, and compression
- `.DS_Store` scan skips package descendants (`.app` bundles, etc.) via `skipsPackageDescendants`
- Each category scan can report intermediate progress via a callback/AsyncStream

### 4.2 AppInventory

Builds a comprehensive map of installed applications.

```
AppInventory (actor)
├── loadAllApps() async -> [InstalledApp]
│   ├── Enumerates /Applications/ recursively (handles subdirectories)
│   ├── Enumerates ~/Applications/
│   ├── Reads Info.plist for each .app bundle:
│   │   ├── CFBundleIdentifier
│   │   ├── CFBundleDisplayName / CFBundleName
│   │   ├── CFBundleShortVersionString
│   │   └── CFBundleIconFile / CFBundleIconName
│   ├── Computes bundle size
│   ├── Loads app icon via NSWorkspace.icon(forFile:)
│   └── Marks system/Apple apps
│
├── installedBundleIdentifiers() async -> Set<String>
│   └── Returns lowercased set of all bundle IDs
│
├── findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem]
│   ├── Searches ~/Library/Application Support/
│   ├── Searches ~/Library/Caches/
│   ├── Searches ~/Library/Preferences/ (*.plist files matching bundle ID)
│   ├── Searches ~/Library/Containers/
│   ├── Searches ~/Library/Group Containers/
│   ├── Searches ~/Library/Saved Application State/
│   ├── Searches ~/Library/WebKit/
│   ├── Searches ~/Library/HTTPStorages/
│   ├── Searches ~/Library/Logs/
│   └── Searches ~/Library/LaunchAgents/ (parses plist Label field)
│
└── appLastUsedDate(at: URL) -> Date?
    └── Uses MDItemCreateWithURL + kMDItemLastUsedDate (Spotlight metadata)
```

### 4.3 OrphanDetector

Identifies files that belong to apps no longer installed.

```
OrphanDetector (actor)
├── detectOrphans() async -> [OrphanedApp]
│   ├── Gets installed bundle IDs from AppInventory
│   ├── Scans each Library subdirectory
│   ├── For each entry, attempts to match against installed apps
│   ├── Unmatched entries → candidate orphans
│   ├── Filters out protected/excluded entries
│   ├── Groups by inferred app name
│   ├── Assigns confidence scores
│   └── Sorts by total size descending
│
├── matchesInstalledApp(name: String, installedIDs: Set<String>) -> Bool
│   ├── Direct match: name exists in installedIDs
│   ├── Prefix match: name starts with a known bundle ID
│   ├── Contains match: any installed ID contains name (or vice versa)
│   └── Normalized match: remove dots/hyphens, compare
│
└── assignConfidence(orphan: OrphanedApp) -> OrphanConfidence
    ├── High: found in Saved Application State + exact bundle ID pattern
    ├── Medium: bundle ID pattern but not in Saved Application State
    └── Low: name-only match, no bundle ID pattern
```

### 4.4 AppUninstaller

Handles the complete removal of an application.

```
AppUninstaller (actor)
├── prepareUninstall(app: InstalledApp) async -> UninstallPlan
│   ├── Finds all associated files via AppInventory.findAssociatedFiles()
│   ├── Checks if app is currently running
│   ├── Calculates total size to be freed
│   └── Returns plan with all files and metadata
│
├── executeUninstall(plan: UninstallPlan, moveToTrash: Bool) -> AsyncStream<UninstallProgress>
│   ├── If app is running: attempt graceful termination
│   │   ├── NSRunningApplication.terminate()
│   │   ├── Wait up to 5 seconds
│   │   └── If still running: report and abort (don't force-kill without user consent)
│   ├── Remove associated Library files first
│   ├── Remove the .app bundle last (so if interrupted, app still shows as installed)
│   ├── Log every deletion via os.Logger
│   └── Finishes with .complete(CleanReport)
│
├── forceQuitApp(bundleIdentifier: String) async -> Bool
│   ├── NSRunningApplication.forceTerminate()
│   └── Only called when user explicitly confirms force-quit
│
└── isAppRunning(bundleIdentifier: String) -> Bool
    └── Checks NSWorkspace.shared.runningApplications
```

**`UninstallPlan`:**
```swift
struct UninstallPlan {
    let app: InstalledApp
    let filesToRemove: [CleanableItem]    // All files including .app bundle
    let totalSize: Int64
    let isRunning: Bool
    let isProtected: Bool
    let requiresForceQuit: Bool
}
```

### 4.5 FileCleaner

Safely removes files from disk.

```
FileCleaner (actor)
├── clean(items: [CleanableItem], moveToTrash: Bool) -> AsyncStream<CleanProgress>
│   ├── Logs all target paths before starting
│   ├── Iterates items sequentially (parallel deletion is risky)
│   ├── Yields progress for each item
│   └── Finishes with .complete(CleanReport)
│
└── estimateCleanSize(items: [CleanableItem]) -> Int64
    └── Sum of selected items' sizes (no I/O needed)
```

### 4.6 PermissionChecker

Detects system permission status.

```
PermissionChecker (static methods)
├── hasFullDiskAccess: Bool
│   ├── Attempts to read ~/Library/Mail (TCC-protected)
│   └── Returns true if readable, false otherwise
│
├── requestFullDiskAccess()
│   └── Opens System Settings → Privacy & Security → Full Disk Access
│
└── canAccessPath(_ path: URL) -> Bool
    └── FileManager.isReadableFile(atPath:)
```

### 4.7 RunningAppDetector

Detects which applications are currently running.

```
RunningAppDetector (static methods)
├── runningBundleIdentifiers() -> Set<String>
│   └── NSWorkspace.shared.runningApplications.map(\.bundleIdentifier)
│
├── isRunning(bundleIdentifier: String) -> Bool
│   └── Check against running set
│
├── terminate(bundleIdentifier: String) -> Bool
│   ├── Find NSRunningApplication by bundle ID
│   └── Call terminate() (graceful)
│
└── forceTerminate(bundleIdentifier: String) -> Bool
    └── Call forceTerminate() (immediate)
```

---

## 5. ViewModel Layer

### 5.1 ScanViewModel

State machine that drives the entire scan/clean UI flow.

```swift
@Observable
class ScanViewModel {
    // MARK: - State
    enum State: Equatable {
        case idle
        case scanning(progress: Double, currentCategory: String)
        case results
        case cleaning(progress: Double, currentItem: String)
        case done(report: CleanReport)
        case error(message: String)
    }

    var state: State = .idle
    var scanResult: ScanResult?
    var selectedSize: Int64 { scanResult?.selectedSize ?? 0 }

    // MARK: - Actions
    func startScan() async
    func cancelScan()
    func startClean() async
    func reset()
    func toggleCategory(_ id: UUID)
    func toggleItem(_ itemId: UUID, in categoryId: UUID)
    func toggleOrphan(_ id: UUID)
    func toggleOrphanLocation(_ itemId: UUID, in orphanId: UUID)
    func selectAll()
    func deselectAll()
}
```

**State transitions:**
```
idle ──[startScan]──→ scanning ──[complete]──→ results ──[startClean]──→ cleaning ──[complete]──→ done
 ↑                      │                       │                                                  │
 └──────────────────────┘ [cancel]               └──[reset]────────────────────────────────────────┘
                                                                                                   │
                                                 └──────────────────[reset]────────────────────────┘
```

### 5.2 UninstallerViewModel

Drives the app uninstaller section.

```swift
@Observable
class UninstallerViewModel {
    // MARK: - State
    enum State: Equatable {
        case loading
        case ready
        case preparingUninstall(app: InstalledApp)
        case confirming(plan: UninstallPlan)
        case uninstalling(progress: Double)
        case done(report: CleanReport)
    }

    var state: State = .loading
    var apps: [InstalledApp] = []
    var filteredApps: [InstalledApp] { /* filtered by searchText and sorted */ }
    var selectedApp: InstalledApp?
    var searchText: String = ""
    var sortOrder: SortOrder = .name

    enum SortOrder { case name, size, lastUsed }

    // MARK: - Actions
    func loadApps() async
    func selectApp(_ app: InstalledApp) async
    func prepareUninstall() async
    func confirmUninstall() async
    func cancelUninstall()
    func handleAppDrop(url: URL) async          // Drag-and-drop .app
}
```

---

## 6. View Layer

### 6.1 App Entry Point

```swift
@main
struct BroomApp: App {
    @State private var scanViewModel = ScanViewModel()
    @State private var uninstallerViewModel = UninstallerViewModel()

    var body: some Scene {
        // Main application window
        Window("Broom", id: "main") {
            MainWindow(
                scanViewModel: scanViewModel,
                uninstallerViewModel: uninstallerViewModel
            )
        }
        .defaultSize(width: 750, height: 520)
        .windowResizability(.contentMinSize)

        // Settings (Cmd+,)
        Settings {
            SettingsView()
        }
    }
}
```

**Key points:**
- `Window` for a single standard desktop app window
- Single main window with `NavigationSplitView` for sidebar navigation
- Cleaner and Uninstaller are sidebar sections within the same window
- `Settings` scene for the preferences window (accessible via Cmd+, and toolbar affordances)
- Standard Dock icon — no `LSUIElement` flag

### 6.2 View Hierarchy

```
MainWindow (NavigationSplitView)
├── Sidebar content
│   ├── "Clean" navigation item (SF Symbol: magnifyingglass)
│   ├── "Apps" navigation item (SF Symbol: shippingbox)
│   └── Optional Settings shortcut / affordance
│
├── CleanerView (detail when "Clean" selected)
│   ├── IdleView
│   │   ├── PermissionBanner (conditional)
│   │   ├── "Scan System" button
│   │   └── "Last scan: X ago" label
│   │
│   ├── ScanningView
│   │   ├── ProgressView (circular or bar)
│   │   ├── Current category label
│   │   ├── "Found X so far" label
│   │   └── "Cancel" button
│   │
│   ├── ScanResultsView
│   │   ├── Total size header
│   │   ├── ScrollView of CategoryRowView items
│   │   │   └── Each row: toggle + icon + name + size + chevron
│   │   ├── Orphan section (if any, with confidence badges)
│   │   ├── "Selected: X" label
│   │   ├── "Clean Selected" button
│   │   └── "Re-scan" button
│   │
│   ├── CategoryDetailView (navigation push)
│   │   ├── Back button with category name
│   │   ├── "Select All" toggle
│   │   ├── ScrollView of individual CleanableItem rows
│   │   └── Selected size summary
│   │
│   ├── CleanProgressView
│   │   ├── ProgressView (determinate)
│   │   ├── Current item path
│   │   └── Items cleaned / total
│   │
│   └── CleanDoneView
│       ├── Checkmark icon
│       ├── "Freed X" label
│       ├── Error summary (if partial failure)
│       └── "Scan Again" button
│
├── UninstallerView (detail when "Apps" selected)
│   ├── HSplitView
│   │   ├── AppListView (left, 250px)
│   │   │   ├── Search bar
│   │   │   ├── Sort controls
│   │   │   └── List of AppRowView
│   │   │       └── App icon + name + total size
│   │   │
│   │   └── AppDetailView (right, flexible)
│   │       ├── App icon (large) + name + version
│   │       ├── "Last used: X" label
│   │       ├── List of associated files with toggles
│   │       ├── Total size
│   │       └── "Uninstall" button (red, prominent)
│   │
│   └── Drop zone overlay ("Drop a .app here to uninstall")
│
Settings scene / SettingsView
├── GeneralSettingsView
├── CleaningSettingsView
├── SafeListSettingsView
└── AboutSettingsView
```

---

## 7. Concurrency Model

All heavy operations use Swift Structured Concurrency:

```
Main Actor (UI thread)
├── All SwiftUI views
├── All @Observable ViewModels
└── Property updates that trigger UI refresh

Background (actor-isolated)
├── FileScanner.scanAll()          → runs on FileScanner actor
├── FileCleaner.clean()            → runs on FileCleaner actor
├── AppInventory.loadAllApps()     → runs on AppInventory actor
├── OrphanDetector.detectOrphans() → runs on OrphanDetector actor
└── AppUninstaller.execute()       → runs on AppUninstaller actor
```

**Rules:**
1. ViewModels call services with `await` — Swift handles the actor hop automatically
2. ViewModels update their `@Observable` properties on return — SwiftUI updates the UI
3. No manual `DispatchQueue`, no locks, no semaphores
4. Cancellation: use `Task` handles stored in ViewModels, call `.cancel()` on user cancellation

**Progress reporting pattern:**
```swift
// Service reports progress via AsyncStream
func scanAll() -> AsyncStream<ScanProgress> {
    AsyncStream { continuation in
        Task {
            continuation.yield(.scanning(category: "System Caches", progress: 0.1))
            let caches = await scanSystemCaches()
            continuation.yield(.scanning(category: "Browser Caches", progress: 0.3))
            let browsers = await scanBrowserCaches()
            // ...
            continuation.yield(.complete(result))
            continuation.finish()
        }
    }
}

// ViewModel consumes the stream
func startScan() async {
    state = .scanning(progress: 0, currentCategory: "")
    for await progress in scanner.scanAll() {
        switch progress {
        case .scanning(let category, let pct):
            state = .scanning(progress: pct, currentCategory: category)
        case .complete(let result):
            scanResult = result
            state = .results
        }
    }
}
```

---

## 8. Permissions & Security

### 8.1 Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Sandboxing disabled — required for file system access -->
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

### 8.2 Info.plist

```xml
<!-- Minimum macOS version -->
<key>LSMinimumSystemVersion</key>
<string>14.0</string>

<!-- Bundle identifier -->
<key>CFBundleIdentifier</key>
<string>com.broom.app</string>

<!-- App name -->
<key>CFBundleName</key>
<string>Broom</string>

<!-- Supported file types for drag-and-drop -->
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeExtensions</key>
        <array><string>app</string></array>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>None</string>
    </dict>
</array>
```

### 8.3 Full Disk Access Detection

The app must work both with and without FDA:

| FDA Status | Behavior |
|------------|----------|
| **Granted** | Full scan: all categories including Safari, Mail, system logs |
| **Not granted** | Partial scan: skip FDA-protected paths, show banner explaining what's missing |

Detection method: attempt `FileManager.isReadableFile(atPath:)` on `~/Library/Mail`.

---

## 9. Error Handling Strategy

```
Level 1: Service Layer (FileScanner, FileCleaner, etc.)
├── Catch all FileManager errors
├── Log via os.Logger
├── Return typed results (success/partial/failure), never throw to callers
└── Continue on individual item failures

Level 2: ViewModel Layer
├── Map service results to UI states
├── Aggregate errors for display
└── Never let errors crash the app

Level 3: View Layer
├── Display user-friendly error messages
├── Offer retry options
└── Show which items failed and why
```

**Error types:**
```swift
enum BroomError: LocalizedError {
    case permissionDenied(path: String)
    case fileInUse(path: String, process: String)
    case pathNotFound(path: String)
    case insufficientDiskSpace
    case scanCancelled

    var errorDescription: String? { /* user-friendly messages */ }
}
```

---

## 10. Testing Strategy

### 10.1 Unit Tests

| Component | Test Approach |
|-----------|--------------|
| **Models** | Direct instantiation, verify computed properties |
| **SizeFormatter** | Test all byte ranges: 0, KB, MB, GB, TB |
| **BundleIDMatcher** | Test exact, prefix, contains, and normalized matching |
| **ExclusionList** | Test hardcoded + user exclusions |
| **FileScanner** | Create temp directory with known structure, verify scan results |
| **OrphanDetector** | Mock AppInventory returning known bundle IDs, verify orphan detection |
| **AppInventory** | Test Info.plist parsing with sample plists |

### 10.2 Integration Tests

| Scenario | Method |
|----------|--------|
| Full scan on real system | Manual — verify results make sense |
| Clean to Trash | Create temp files, clean, verify in Trash |
| Orphan detection accuracy | Uninstall a test app, verify leftovers detected |
| FDA detection | Test with and without FDA granted |
| Uninstall flow | Install a test app, uninstall via Broom, verify complete removal |

### 10.3 UI Tests

- SwiftUI Previews for each view in each state
- Manual testing of all state transitions
- Verify window layout at minimum size — no content clipping
- Verify sidebar navigation during active scan/clean operations

---

## 11. Dependencies

### 11.1 First-Party Frameworks

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | All UI |
| **Foundation** | FileManager, URL, PropertyListSerialization |
| **AppKit** | NSWorkspace, NSImage (app icons), NSApplicationDelegate integration |
| **Observation** | @Observable ViewModels |
| **os** | os.Logger for structured logging |
| **ServiceManagement** | SMAppService for Launch at Login |
| **UserNotifications** | Post-clean notifications |

### 11.2 Third-Party Dependencies

| Dependency | Usage | Optional? |
|------------|-------|-----------|
| **Sparkle** | Auto-update framework | Yes — post-MVP only |

**Philosophy:** Minimize third-party dependencies. The app should build with zero external packages for v1.0. Sparkle can be added for v1.1+.

---

## 12. Build Configuration

### 12.1 Xcode Project Settings

| Setting | Value |
|---------|-------|
| **Swift Language Version** | 5.9+ |
| **Deployment Target** | macOS 14.0 |
| **Architectures** | Universal (arm64, x86_64) |
| **Code Signing** | Sign to Run Locally (dev) / Developer ID Application (release) |
| **Sandbox** | Disabled |
| **Hardened Runtime** | Enabled |
| **Build Configuration** | Debug + Release |

### 12.2 SwiftLint Configuration

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional

excluded:
  - BroomTests/
```
