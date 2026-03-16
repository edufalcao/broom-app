# Broom — Technical Architecture

> **Version:** 1.0.0
> **Date:** 2026-03-15

---

## 1. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                          App Layer                           │
│                                                              │
│  BroomApp ──── AppDelegate ──── AppRouter                    │
│                                                              │
│  Owns the app scenes, menu commands, Dock drop handling,     │
│  and cross-section routing inside the main window.           │
├──────────────────────────────────────────────────────────────┤
│                        SwiftUI Layer                         │
│                                                              │
│  MainWindow ──── CleanerView ──── ScanResultsView            │
│  UninstallerView ──── AppDetailView ──── SettingsView        │
│  LargeFilesView ──── UninstallConfirmView                    │
│                                                              │
│  One desktop-style window with three sidebar sections plus   │
│  a separate Settings scene.                                  │
├──────────────────────────────────────────────────────────────┤
│                      ViewModel Layer                         │
│                                                              │
│  ScanViewModel ──── UninstallerViewModel ────                │
│  LargeFilesViewModel                                         │
│                                                              │
│  @MainActor @Observable classes. State machines driving UI.  │
│  Heavy I/O stays in services; UI state and orchestration     │
│  live here.                                                  │
├──────────────────────────────────────────────────────────────┤
│                    Service Protocol Layer                    │
│                                                              │
│  ScanServing ──── CleanServing ──── AppInventoryServing      │
│  OrphanDetecting ──── AppUninstalling ────                   │
│  LargeFileScanning                                           │
│                                                              │
│  Protocols enable dependency injection and test isolation.   │
├──────────────────────────────────────────────────────────────┤
│                 Service Implementation Layer                 │
│                                                              │
│  FileScanner ──── FileCleaner ──── AppInventory              │
│  OrphanDetector ──── AppUninstaller ──── LargeFileScanner    │
│  PermissionChecker ──── RunningAppDetector ────              │
│  NotificationManager                                         │
│                                                              │
│  Actors isolate file-system work and Spotlight-backed scans. │
│  Preferences are injected as value snapshots.                │
├──────────────────────────────────────────────────────────────┤
│                      Foundation Layer                        │
│                                                              │
│  Constants ──── SizeFormatter ──── Logger ──── SafeDelete    │
│  ExclusionList ──── BundleIDMatcher ──── AppPreferences      │
│  ReleaseNotes                                                │
│                                                              │
│  Stateless helpers and small value types shared everywhere.  │
└──────────────────────────────────────────────────────────────┘
```

**Why MVVM + Service Protocols?**
- MVVM keeps SwiftUI state transitions explicit and easy to test.
- The service protocol layer separates file-system and Spotlight work from UI orchestration.
- Services are mostly `actor`-typed, so concurrency stays safe without manual locking.
- ViewModels communicate through protocols, which keeps tests focused and cheap.
- `AppPreferences` is passed into services as a value snapshot, avoiding hidden global state.
- `AppRouter` centralizes cross-window actions such as keyboard shortcuts and Dock `.app` drops.

---

## 2. Project Structure

```
Broom/
├── BroomApp.swift                          # App scene setup, AppDelegate, AppRouter
├── Info.plist                              # Versioning, document types, bundle metadata
├── Broom.entitlements                      # Non-sandboxed desktop app
├── Assets.xcassets/                        # App icon and asset catalog
│
├── Models/
│   ├── CleanableItem.swift                 # Single file or directory candidate
│   ├── CleanCategory.swift                 # Group of cleaner items
│   ├── ScanResult.swift                    # Cleaner scan result snapshot
│   ├── OrphanedApp.swift                   # Orphan grouping + confidence
│   ├── InstalledApp.swift                  # Installed app + associated files
│   ├── LargeFile.swift                     # Large-file finder result
│   └── CleanReport.swift                   # Post-clean/uninstall summary
│
├── ViewModels/
│   ├── ScanViewModel.swift                 # Cleaner scan, selection, clean flow, Dock badge
│   ├── UninstallerViewModel.swift          # App list, uninstall preview, quit/force-quit flow
│   └── LargeFilesViewModel.swift           # Large-file scan, sort, reveal, clean flow
│
├── Views/
│   ├── MainWindow.swift                    # Main NavigationSplitView and routing
│   ├── Cleaner/                            # Cleaner states and drill-down views
│   ├── LargeFiles/                         # Large-file finder list and rows
│   ├── Uninstaller/                        # App list/detail/uninstall confirmation
│   ├── Settings/                           # Native macOS Settings tabs
│   └── Components/                         # Shared rows, badges, banners, empty states
│
├── Services/
│   ├── ServiceProtocols.swift              # Dependency-injected service interfaces
│   ├── FileScanner.swift                   # Parallel cleaner category scanning
│   ├── FileCleaner.swift                   # Trash or permanent-delete execution
│   ├── AppInventory.swift                  # Standard + Spotlight app discovery
│   ├── OrphanDetector.swift                # Library leftover detection + confidence
│   ├── AppUninstaller.swift                # Uninstall plan creation + execution
│   ├── LargeFileScanner.swift              # Recursive home-directory large-file scan
│   ├── PermissionChecker.swift             # Full Disk Access checks and prompts
│   ├── RunningAppDetector.swift            # Running-app matching and termination helpers
│   └── NotificationManager.swift           # Notification permission and delivery
│
└── Utilities/
    ├── Constants.swift                     # Scan paths and protected locations
    ├── SizeFormatter.swift                 # ByteCountFormatter wrapper
    ├── BundleIDMatcher.swift               # Bundle-ID and app-name matching
    ├── ExclusionList.swift                 # Hardcoded + user safe list logic
    ├── SafeDelete.swift                    # Trash/delete helpers with Result output
    ├── Logger.swift                        # os.Logger categories
    ├── AppPreferences.swift                # Sendable preference snapshot + defaults
    └── ReleaseNotes.swift                  # In-app release note content
```

```
BroomTests/
├── TestSupport.swift                       # Shared mocks and helpers
├── AppInventoryTests.swift
├── AppPreferencesTests.swift
├── AppRouterTests.swift
├── AppUninstallerTests.swift
├── BundleIDMatcherTests.swift
├── DockerHomebrewScanTests.swift
├── ExclusionListTests.swift
├── FileCleanerTests.swift
├── FileScannerTests.swift
├── LargeFileScannerTests.swift
├── LargeFilesViewModelTests.swift
├── ModelTests.swift
├── NotificationManagerTests.swift
├── OrphanCategoryTests.swift
├── OrphanDetectorTests.swift
├── RunningAppDetectorTests.swift
├── ScanViewModelTests.swift
├── SizeFormatterTests.swift
└── UninstallerViewModelTests.swift
```

The current suite runs 72 tests across 21 suites.

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
    var categories: [CleanCategory]
    var orphanedApps: [OrphanedApp]
    let scanDuration: TimeInterval
    let scanDate: Date

    // Computed
    var totalSize: Int64 { categories.reduce(0) { $0 + $1.totalSize } }
    var selectedSize: Int64 { categories.reduce(0) { $0 + $1.selectedSize } }
    var totalItems: Int { categories.reduce(0) { $0 + $1.itemCount } }
    var selectedItems: Int { categories.reduce(0) { $0 + $1.selectedCount } }
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
    var bundleIsSelected: Bool            // Whether the .app bundle itself is selected
    var associatedFiles: [CleanableItem]  // All files in ~/Library/* for this app
    var associatedFilesLoaded: Bool       // Lazy-loading state for associated files
    var lastUsedDate: Date?               // From Spotlight metadata

    // Computed
    var totalSize: Int64 { bundleSize + associatedFiles.reduce(0) { $0 + $1.size } }
    var selectedTotalSize: Int64 { (bundleIsSelected ? bundleSize : 0) + associatedFiles.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var selectedItemCount: Int { (bundleIsSelected ? 1 : 0) + associatedFiles.filter(\.isSelected).count }
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
│   ├── Only includes files older than configurable threshold (default 7 days)
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
├── scanDocker() async -> CleanCategory?
│   ├── Returns nil if Docker data/config is absent
│   └── Scans Docker VM data and local Docker config
│
├── scanHomebrewExtended() async -> CleanCategory?
│   ├── Reports Cellar usage in addition to cache paths
│   └── Starts unselected because old versions may still matter to the user
│
├── scanDownloads() async -> CleanCategory?
│   ├── Returns nil if ~/Downloads is empty or unavailable
│   └── Awareness-only category, defaulting to unselected
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
│   ├── Supplements results with Spotlight-discovered .app bundles in non-standard locations
│   ├── Reads Info.plist for each .app bundle:
│   │   ├── CFBundleIdentifier
│   │   ├── CFBundleDisplayName / CFBundleName
│   │   ├── CFBundleShortVersionString
│   ├── Deduplicates by standardized bundle path
│   ├── Computes bundle size
│   ├── Loads app icon via NSWorkspace.icon(forFile:)
│   └── Marks system/Apple apps
│
├── installedBundleIdentifiers() async -> Set<String>
│   └── Returns lowercased set of all bundle IDs, including Spotlight-supplemented apps
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
│   └── Searches LaunchAgents and LaunchDaemons by parsing plist content
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
│   ├── Assigns confidence scores using Saved State, receipt, and Spotlight signals
│   └── Sorts by total size descending
│
└── assignConfidence(locations:receiptBundleIDs:spotlightBundleIDs:) -> OrphanConfidence
    ├── High: Saved Application State + bundle-ID pattern, or receipt evidence
    ├── Medium: bundle-ID pattern or Spotlight evidence
    └── Low: weak name-only evidence
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
│   ├── Remove associated Library files first
│   ├── Remove the .app bundle last (so if interrupted, app still shows as installed)
│   └── Finishes with .complete(CleanReport)
```

**`UninstallPlan`:**
```swift
struct UninstallPlan {
    let app: InstalledApp
    let filesToRemove: [CleanableItem]    // All files including .app bundle
    let totalSize: Int64
    let isRunning: Bool
    let isProtected: Bool
    var selectedCount: Int { filesToRemove.count }
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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Broom", id: "main") {
            MainWindow()
                .environment(appDelegate.router)
        }
        .defaultSize(width: 750, height: 520)
        .windowResizability(.contentMinSize)
        .commands {
            // Cmd+Shift+S scan shortcut and Cmd+1/2/3 sidebar routing
        }

        Settings {
            SettingsView()
        }
    }
}
```

**Key points:**
- `Window` for a single standard desktop app window
- Single main window with `NavigationSplitView` for sidebar navigation
- Cleaner, Uninstaller, and Large Files are sidebar sections within the same window
- `AppRouter` carries keyboard shortcuts and Dock drop actions into the active window
- `Settings` scene for the preferences window (accessible via Cmd+, and toolbar affordances)
- Standard Dock icon — no `LSUIElement` flag

### 6.2 View Hierarchy

```
MainWindow (NavigationSplitView)
├── Sidebar content
│   ├── "Clean" navigation item (SF Symbol: magnifyingglass)
│   ├── "Apps" navigation item (SF Symbol: shippingbox)
│   └── "Large Files" navigation item (SF Symbol: doc.badge.arrow.up)
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
│   │   ├── Left pane inside UninstallerView
│   │   │   ├── Search bar
│   │   │   ├── Sort controls
│   │   │   ├── List of AppRowView
│   │   │   └── Refresh button
│   │   │
│   │   └── AppDetailView (right, flexible)
│   │       ├── App icon (large) + name + version
│   │       ├── "Last used: X" label
│   │       ├── Bundle row + associated-file rows with toggles
│   │       ├── Selected total
│   │       └── "Uninstall" button (red, prominent)
│   │
│   ├── UninstallConfirmView (sheet)
│   └── Running-app alerts for quit / force-quit confirmation
│
├── LargeFilesView (detail when "Large Files" selected)
│   ├── Idle state with minimum-size picker
│   ├── Scanning state with current path
│   ├── Results list of LargeFileRowView
│   └── Done state after moving files to Trash
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

**Philosophy:** Minimize third-party dependencies. The app builds with zero external packages today. Sparkle remains an optional future addition.

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
