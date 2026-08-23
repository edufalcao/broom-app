# Broom — Technical Architecture

> **Version:** 1.5.0
> **Date:** 2026-08-22

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
│  LargeFilesView ──── InstallersView ────                     │
│  ProjectArtifactsView ──── UninstallConfirmView              │
│                                                              │
│  One desktop-style window with four sidebar sections plus    │
│  a separate Settings scene.                                  │
├──────────────────────────────────────────────────────────────┤
│                      ViewModel Layer                         │
│                                                              │
│  ScanViewModel ──── UninstallerViewModel ────                │
│  LargeFilesViewModel ──── ProjectArtifactsViewModel ────     │
│  InstallersViewModel                                         │
│                                                              │
│  @MainActor @Observable classes. State machines driving UI.  │
│  Heavy I/O stays in services; UI state and orchestration     │
│  live here.                                                  │
├──────────────────────────────────────────────────────────────┤
│                    Service Protocol Layer                    │
│                                                              │
│  ScanServing ──── CleanServing ──── AppInventoryServing      │
│  OrphanDetecting ──── AppUninstalling ────                   │
│  LargeFileScanning ──── ProjectArtifactScanning ────         │
│  InstallerScanning                                           │
│                                                              │
│  Protocols enable dependency injection and test isolation.   │
├──────────────────────────────────────────────────────────────┤
│                 Service Implementation Layer                 │
│                                                              │
│  FileScanner ──── FileCleaner ──── AppInventory               │
│  OrphanDetector ──── AppUninstaller ──── LargeFileScanner    │
│  ProjectArtifactScanner ──── InstallerScanner ────           │
│  RecencyClassifier ──── UninstallArtifactPlanner ────        │
│  LaunchServicesManager ──── LoginItemManager ────            │
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
│  DeletePolicy ──── ProtectedDataPolicy ──── ReleaseNotes     │
│  ZipInspector                                                │
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
│   ├── InstalledApp.swift                  # Installed app, InstalledAppSnapshot
│   ├── UninstallArtifactSource.swift       # Source tag for uninstall artifacts
│   ├── ProjectArtifact.swift               # Regenerable project artifact + ArtifactRecency, ProjectGroup
│   ├── LargeFile.swift                     # Large-file finder result
│   └── CleanReport.swift                   # Post-clean/uninstall summary
│
├── ViewModels/
│   ├── ScanViewModel.swift                 # Cleaner scan, selection, clean flow, Dock badge
│   ├── UninstallerViewModel.swift          # App list, uninstall preview, quit/force-quit flow
│   ├── LargeFilesViewModel.swift           # Large-file scan, sort, reveal, clean flow
│   ├── InstallersViewModel.swift           # Installer leftovers scan and clean flow
│   └── ProjectArtifactsViewModel.swift     # Per-project artifact scan, selection, clean flow
│
├── Views/
│   ├── MainWindow.swift                    # Main NavigationSplitView and routing
│   ├── Cleaner/                            # Cleaner states and drill-down views
│   ├── LargeFiles/                         # Large-file finder list, rows, Installers mode
│   ├── ProjectArtifacts/                   # Per-project artifact results
│   ├── Uninstaller/                        # App list/detail/uninstall confirmation
│   ├── Settings/                           # Native macOS Settings tabs
│   └── Components/                         # Shared rows, badges, banners, empty states
│
├── Services/
│   ├── ServiceProtocols.swift              # Dependency-injected service interfaces
│   ├── FileScanner.swift                   # Parallel cleaner category scanning
│   ├── FileCleaner.swift                   # Trash or permanent-delete execution
│   ├── AppInventory.swift                  # Standard + Spotlight app discovery + snapshot
│   ├── OrphanDetector.swift                # Suppression-first orphan detection
│   ├── AppUninstaller.swift                # Uninstall plan creation + execution
│   ├── UninstallArtifactPlanner.swift      # 11-provider artifact discovery for uninstalls
│   ├── LaunchServicesManager.swift         # Unregister apps and refresh LS database
│   ├── LoginItemManager.swift              # Unload launch agents/daemons
│   ├── LargeFileScanner.swift              # Recursive home-directory large-file scan
│   ├── InstallerScanner.swift              # Leftover installer files + app-bearing ZIP archives
│   ├── ProjectArtifactScanner.swift        # Project discovery + regenerable artifact scanning
│   ├── RecencyClassifier.swift             # Recent/old/uncertain classification by mtime
│   ├── PermissionChecker.swift             # Full Disk Access checks and prompts
│   ├── RunningAppDetector.swift            # Running-app matching and termination helpers
│   └── NotificationManager.swift           # Notification permission and delivery
│
└── Utilities/
    ├── Constants.swift                     # Scan paths and protected locations
    ├── SizeFormatter.swift                 # ByteCountFormatter wrapper
    ├── BundleIDMatcher.swift               # Strict (orphan) and broad (uninstall) matching
    ├── ExclusionList.swift                 # Hardcoded + user safe list logic
    ├── SafeDelete.swift                    # Policy-aware trash/delete execution boundary
    ├── DeletePolicy.swift                  # Path validation, symlink checks, protected data
    ├── ProtectedDataPolicy.swift           # Protected data family definitions
    ├── Logger.swift                        # os.Logger categories
    ├── AppPreferences.swift                # Sendable preference snapshot + defaults
    ├── ZipInspector.swift                  # In-process ZIP central-directory inspection
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
├── CleanerEnrichmentTests.swift
├── DeletePolicyTests.swift
├── DockerHomebrewScanTests.swift
├── ExclusionListTests.swift
├── FileCleanerTests.swift
├── FileScannerTests.swift
├── InstallerScannerTests.swift
├── LargeFileScannerTests.swift
├── LargeFilesViewModelTests.swift
├── MetadataCleanupTests.swift
├── ModelTests.swift
├── NotificationManagerTests.swift
├── OrphanCategoryTests.swift
├── OrphanDetectorTests.swift
├── ProjectArtifactTests.swift
├── ProtectedDataPolicyTests.swift
├── RunningAppDetectorTests.swift
├── ScanViewModelTests.swift
├── SizeFormatterTests.swift
├── UninstallArtifactPlannerTests.swift
├── UninstallerViewModelTests.swift
└── ZipInspectorTests.swift

BroomUITests/
└── BroomUITests.swift                      # Main-window smoke tests
```

Run the full suite with `xcodebuild -scheme Broom test`.

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
    let itemsBlocked: Int           // Blocked by safety rules (DeletePolicy)
    let errors: [CleanError]
    let duration: TimeInterval

    struct CleanError {
        let path: URL
        let reason: String
    }
}
```

### 3.7 ProjectArtifact

A regenerable build artifact found inside a project directory. Shared cache stores never appear here; those belong to the Cleaner.

```swift
enum ArtifactRecency: String {
    case recent     // Shown as "Active"
    case old        // Shown as "Old"
    case uncertain  // Treated as protected; shown as "Unknown age"
}

struct ProjectArtifact: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let recency: ArtifactRecency
    var isSelected: Bool            // Starts true only for .old (suppression-first)

    var formattedSize: String { SizeFormatter.format(size) }
}

struct ProjectGroup: Identifiable {
    let path: URL                   // Owning project directory
    var artifacts: [ProjectArtifact]

    var name: String { path.lastPathComponent }
    var totalSize: Int64 { artifacts.reduce(0) { $0 + $1.size } }
}
```

### 3.8 LargeFile

A large file found by the Large File Scanner, also reused for installer leftovers.

```swift
struct LargeFile: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let size: Int64
    let modifiedDate: Date
    var isSelected: Bool
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

Builds a comprehensive map of installed applications. Also produces an `InstalledAppSnapshot` used by the orphan detector to match candidates against the live system state.

```
AppInventory (actor)
├── loadAllApps() async -> [InstalledApp]
│   ├── Enumerates /Applications/ recursively (handles subdirectories)
│   ├── Enumerates ~/Applications/
│   ├── Enumerates extended discovery roots (System/Applications, Homebrew Caskroom, Setapp)
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
├── buildSnapshot() async -> InstalledAppSnapshot
│   ├── Collects installed bundle IDs (lowercased) and app URLs
│   ├── Collects running bundle IDs via NSWorkspace
│   ├── Collects launch item labels from LaunchAgents/LaunchDaemons
│   └── Used by OrphanDetector as a single point-in-time view of system state
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

**`InstalledAppSnapshot`:**
```swift
struct InstalledAppSnapshot: Sendable {
    let installedBundleIDs: Set<String>
    let installedAppURLs: Set<URL>
    let runningBundleIDs: Set<String>
    let launchItemLabels: Set<String>
}
```

### 4.3 OrphanDetector

Identifies files that belong to apps no longer installed. Uses a suppression-first architecture: every candidate must pass all nine suppression gates before being surfaced to the user. This ensures only stale, high-confidence leftovers appear in results.

```
OrphanDetector (actor)
├── detectOrphans() async -> [OrphanedApp]
│   ├── Builds an InstalledAppSnapshot from AppInventory
│   ├── Loads receipt bundle IDs and Spotlight bundle IDs
│   ├── Scans each Library subdirectory
│   ├── For each entry, applies 9 suppression gates:
│   │   1. Pattern gate: only reverse-DNS, .savedState, .binarycookies, and Preferences .plist
│   │   2. Exclusion list (built-in + user safe list)
│   │   3. Protected data family (ProtectedDataPolicy)
│   │   4. Installed app match (strictMatch against snapshot)
│   │   5. Running app match (strictMatch against running bundle IDs)
│   │   6. Launch item label match
│   │   7. Spotlight/LaunchServices existence (suppresses if still registered)
│   │   8. Size threshold (< 4 KB suppressed)
│   │   9. Stale-age threshold (recently modified items suppressed, default 30 days)
│   ├── Surviving candidates grouped by inferred app name
│   ├── Assigns confidence scores
│   └── Sorts by total size descending
│
└── assignConfidence(locations:receiptBundleIDs:spotlightBundleIDs:) -> OrphanConfidence
    ├── High: Saved Application State + bundle-ID pattern, or receipt evidence
    ├── Medium: bundle-ID pattern
    └── Low: weak evidence only
```

**Design rationale:** Spotlight and receipt signals are used as suppression inputs (if Spotlight still knows about the app, suppress the candidate) rather than confidence boosters. This avoids surfacing ambiguous results that could lead to accidental deletion.

### 4.4 AppUninstaller

Handles the complete removal of an application. Delegates artifact discovery to `UninstallArtifactPlanner` and performs pre-delete and post-delete metadata cleanup via `LoginItemManager` and `LaunchServicesManager`.

```
AppUninstaller (actor)
├── prepareUninstall(app: InstalledApp) async -> UninstallPlan
│   ├── Uses UninstallArtifactPlanner to discover all artifacts (11 providers)
│   ├── Checks if app is currently running
│   ├── Calculates total size to be freed
│   └── Returns plan with all files, tagged by UninstallArtifactSource
│
├── executeUninstall(plan: UninstallPlan, moveToTrash: Bool) -> AsyncStream<UninstallProgress>
│   ├── Pre-delete: unload launch agents/daemons (LoginItemManager)
│   ├── Pre-delete: remove login items
│   ├── Remove associated Library files first
│   ├── Remove the .app bundle last (so if interrupted, app still shows as installed)
│   ├── Post-delete: unregister app from LaunchServices (LaunchServicesManager)
│   ├── Post-delete: refresh LaunchServices database
│   ├── Reports progress via UninstallPhase enum
│   └── Finishes with .complete(CleanReport)
│   Note: all metadata cleanup steps are non-fatal — failures are logged but do not block uninstall.
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

### 4.4.1 UninstallArtifactPlanner

Discovers all files associated with an application using 11 artifact providers. Each artifact is tagged with an `UninstallArtifactSource` for grouped display in the UI.

```
UninstallArtifactPlanner (struct)
├── planArtifacts(for app: InstalledApp) -> [CleanableItem]
│   ├── Generates name variants (no-space, hyphenated, underscored, lowercase, version/channel trimmed)
│   ├── Deduplicates by standardized path
│   ├── Queries 11 artifact providers:
│   │   1. User data (Application Support, Containers)
│   │   2. Preferences (plists, ByHost)
│   │   3. Caches
│   │   4. Group Containers
│   │   5. Web data (WebKit, Cookies, HTTPStorages)
│   │   6. Saved Application State
│   │   7. Logs and DiagnosticReports
│   │   8. Launch items (agents, daemons)
│   │   9. Privileged helper tools
│   │   10. Package receipts (/var/db/receipts)
│   │   11. Application Scripts
│   └── Returns items sorted by size descending
```

### 4.4.2 LaunchServicesManager

Cleans up LaunchServices metadata after an app is deleted.

```
LaunchServicesManager (struct)
├── unregisterApp(at bundlePath: URL) -> Bool
│   └── Runs lsregister -u to remove the app from the LS database
│
└── refreshDatabase() -> Bool
    └── Runs lsregister -kill -r to rebuild the LS database (10-second timeout)
```

### 4.4.3 LoginItemManager

Unloads launch agents and daemons that belong to the app being uninstalled.

```
LoginItemManager (struct)
├── removeLoginItems(matching bundleID: String) -> [URL]
│   ├── Searches user and system LaunchAgents and LaunchDaemons
│   ├── Matches plist filenames against the bundle ID
│   └── Unloads each match via launchctl
│
├── unloadLaunchAgent(at path: URL) -> Bool
└── unloadLaunchDaemon(at path: URL) -> Bool
```

### 4.5 FileCleaner

Safely removes files from disk. All deletions go through `SafeDelete`, which validates each path against `DeletePolicy` before operating.

```
FileCleaner (actor)
├── clean(items: [CleanableItem], moveToTrash: Bool) -> AsyncStream<CleanProgress>
│   ├── Logs all target paths before starting
│   ├── Iterates items sequentially (parallel deletion is risky)
│   ├── Each item yields a DeleteResult (success/blocked/failed)
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

### 4.8 SafeDelete and DeletePolicy

`SafeDelete` is the single execution boundary for all file deletions. Before trashing or permanently deleting a file, it validates the path through `DeletePolicy`.

```
SafeDelete (enum, static methods)
├── moveToTrash(_ url:, context:, expectedSize:) -> DeleteResult
└── deletePermanently(_ url:, context:, expectedSize:) -> DeleteResult
    Both validate through DeletePolicy.validate() before operating.

DeletePolicy (enum, static methods)
├── validate(path: URL, context: DeleteContext) -> DeleteValidationResult
│   ├── Rejects relative paths
│   ├── Blocks protected system prefixes (/System, /usr, /bin, /sbin, /Library/Apple, /private/var/db)
│   ├── Allows /var/db/receipts in explicitUninstall context only
│   ├── Blocks missing paths
│   ├── Blocks symlinks that resolve to protected locations
│   ├── Blocks protected data families in genericClean context (via ProtectedDataPolicy)
│   └── Blocks paths where the parent directory is not writable
```

**`DeleteContext`** distinguishes generic cleanup scans (`.genericClean`) from explicit user-initiated uninstalls (`.explicitUninstall`). Protected data families and receipt paths are treated differently depending on the context.

**`DeleteResult`** is a three-case enum: `.success`, `.blocked(reason)`, or `.failed(error)`.

### 4.9 ProtectedDataPolicy

Defines data families whose leftovers should never appear in generic orphan scans because accidental deletion could cause data loss or security issues.

Six protected families:
1. **Password managers** (1Password, LastPass, Bitwarden, KeePassXC, Dashlane, Enpass, RoboForm)
2. **VPN / proxy tools** (Mullvad, NordVPN, ExpressVPN, WireGuard, Tailscale, PIA, Surfshark, ProtonVPN)
3. **Browsers** (Safari, Chrome, Firefox, Thunderbird, Arc, Brave, Edge, Opera, Vivaldi)
4. **AI model / assistant data** (ChatGPT, Claude, Copilot, LM Studio, Ollama)
5. **iCloud-synced data** (iCloud, MobileSync, CloudDaemon, Bird)
6. **Automation tools** (Keyboard Maestro, Alfred, Raycast, Hammerspoon, BetterTouchTool, Rectangle, Karabiner)

Matching uses both bundle ID prefixes and path component substrings.

### 4.10 BundleIDMatcher

Provides two matching strategies for different safety contexts:

- **`strictMatch`** (used by OrphanDetector): exact match or reverse-DNS prefix relationship only. Minimizes false negatives to avoid suppressing true orphans, but also avoids false positives from loose name matching.
- **`broadMatch`** (used by UninstallArtifactPlanner): adds stripped-punctuation matching and short-name substring matching. Acceptable here because the user explicitly chose the app to uninstall.

### 4.11 ProjectArtifactScanner

Discovers project directories under user-configured search roots and collects their regenerable build artifacts. Shared cache stores never appear here; those belong to the Cleaner.

```
ProjectArtifactScanner (actor)
├── scan() -> AsyncStream<ProjectArtifactScanProgress>
│   ├── For each search root that exists on disk:
│   │   ├── discoverProjects(below root) — directories containing a project
│   │   │   indicator (.git, package.json, Cargo.toml, go.mod, …), up to
│   │   │   depth 4; heavy artifact directories are not descended into
│   │   └── collectArtifacts(project:) — family-named directories at or below
│   │       the project root up to depth 2 (covers monorepo layouts), plus
│   │       CACHEDIR.TAG-marked children of the project itself
│   ├── Sizes computed with nested artifacts pruned (no double-counting)
│   ├── Each artifact classified via RecencyClassifier
│   └── Finishes with .complete([ProjectGroup]) sorted by size descending
│
└── liveRoots() -> [URL]
    └── User-configured roots win; fixed defaults apply when none are set
```

**Suppression-first behavior:** only confidently-old artifacts start selected; recent and uncertain ones are deselected and re-checked at delete time (`RecencyClassifier.isActive`).

### 4.12 InstallerScanner

Finds leftover installer files for the Large Files section's Installers mode.

```
InstallerScanner (actor)
├── scan() -> AsyncStream<InstallerScanProgress>
│   ├── Sources: ~/Downloads, ~/Desktop, ~/Documents, Homebrew download cache
│   ├── Matches .dmg/.pkg/.mpkg/.iso/.xip extensions, max depth 2
│   ├── App-bearing ZIP archives identified via ZipInspector central-directory peek
│   ├── Uniform age gate: files younger than installerMinAgeDays suppressed
│   └── Mounted disk images never offered regardless of age
│
└── mountedDiskImagePaths() -> Set<String>
    └── Reads mounted volumes so active .dmg mounts are excluded
```

**ZipInspector** (Utilities) reads the ZIP end-of-central-directory record in-process and inspects entry names — no third-party dependency, no full extraction — to decide whether an archive contains an .app bundle.

### 4.13 RecencyClassifier

Labels an artifact directory as recent, old, or uncertain against a modification-time cutoff. Uncertainty is treated as protected, matching Broom's suppression-first orphan philosophy.

```
RecencyClassifier (struct)
├── classify(at: URL) -> ArtifactRecency
│   ├── Top-level mtime after cutoff → .recent
│   ├── Bounded recursive probe of descendants (default 20,000 entries)
│   ├── Unreadable or missing mtimes → .uncertain
│   ├── Probe budget exhausted before proving quiet → .uncertain
│   └── All probed dates before cutoff → .old
│
└── isActive(at: URL) -> Bool
    └── Delete-time re-check: anything not provably .old is active
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

### 5.3 ProjectArtifactsViewModel

Drives the Project Artifacts section.

```swift
@Observable
class ProjectArtifactsViewModel {
    enum State: Equatable {
        case idle
        case scanning(currentPath: String, artifactsFound: Int)
        case results
        case cleaning(cleaned: Int, total: Int)
        case done(freedBytes: Int64, itemsCleaned: Int)
    }

    var state: State = .idle
    var groups: [ProjectGroup] = []
    var selectedSize: Int64 { /* sum of selected artifacts */ }

    // MARK: - Actions
    func startScan()
    func cancelScan()
    func toggleArtifact(_ id: UUID)
    func setGroup(_ group: ProjectGroup, selected: Bool)  // Explicit target state
    func startClean() / confirmClean()                     // Re-checks recency at delete time
    func reset()
    func revealInFinder(_ artifact: ProjectArtifact)
}
```

### 5.4 InstallersViewModel

Drives the Installers mode of the Large Files section. Same state-machine shape as `LargeFilesViewModel`, scanning via `InstallerScanner` instead of `LargeFileScanner`.

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
            // Cmd+Shift+S scan shortcut and Cmd+1/2/3/4 sidebar routing
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
- Cleaner, Uninstaller, Artifacts, and Large Files are sidebar sections within the same window
- `AppRouter` carries keyboard shortcuts and Dock drop actions into the active window
- `Settings` scene for the preferences window (accessible via Cmd+, and toolbar affordances)
- Standard Dock icon — no `LSUIElement` flag

### 6.2 View Hierarchy

```
MainWindow (NavigationSplitView)
├── Sidebar content
│   ├── "Clean" navigation item (SF Symbol: magnifyingglass)
│   ├── "Uninstall" navigation item (SF Symbol: shippingbox)
│   ├── "Artifacts" navigation item (SF Symbol: archivebox)
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
├── ProjectArtifactsView (detail when "Artifacts" selected)
│   ├── Idle state with scan button
│   ├── Scanning state with current path and artifact count
│   ├── Results grouped by project (ProjectGroup rows with per-artifact toggles,
│   │   recency labels, group header set-selected action)
│   ├── Clean confirmation
│   └── Done state with freed summary
│
├── LargeFilesView (detail when "Large Files" selected)
│   ├── Idle state with minimum-size picker
│   ├── Scanning state with current path
│   ├── Results list of LargeFileRowView
│   ├── Installers mode (segment): leftover installers and app-bearing ZIPs
│   └── Done state after moving files to Trash
│
Settings scene / SettingsView
├── GeneralSettingsView
├── CleaningSettingsView
├── ProjectsSettingsView
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
├── AppInventory.buildSnapshot()   → runs on AppInventory actor
├── OrphanDetector.detectOrphans() → runs on OrphanDetector actor
├── AppUninstaller.execute()       → runs on AppUninstaller actor
├── ProjectArtifactScanner.scan()  → runs on ProjectArtifactScanner actor
└── InstallerScanner.scan()        → runs on InstallerScanner actor

Synchronous (called from actor context)
├── UninstallArtifactPlanner.planArtifacts()  → struct, called within AppUninstaller
├── LaunchServicesManager.unregisterApp()     → struct, subprocess invocation
├── LoginItemManager.removeLoginItems()       → struct, subprocess invocation
├── DeletePolicy.validate()                   → static, pure validation
└── ProtectedDataPolicy.isProtected()         → static, pure lookup
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
| **BundleIDMatcher** | Test strictMatch and broadMatch strategies, edge cases |
| **ExclusionList** | Test hardcoded + user exclusions |
| **FileScanner** | Create temp directory with known structure, verify scan results |
| **OrphanDetector** | Mock AppInventory snapshot, verify all 9 suppression gates |
| **AppInventory** | Test Info.plist parsing with sample plists |
| **UninstallArtifactPlanner** | Test all 11 providers, name variant generation, deduplication |
| **DeletePolicy** | Test system path blocking, symlink safety, context-dependent behavior |
| **ProtectedDataPolicy** | Test bundle ID and path component matching for all 6 families |
| **MetadataCleanup** | Test LaunchServicesManager and LoginItemManager integration |
| **InstallerScanner** | Temp fixtures for installer extensions, age gate, mounted-image exclusion, ZIP detection |
| **ProjectArtifactScanner** | Temp project trees: indicator discovery, artifact families, CACHEDIR.TAG, nested pruning |
| **RecencyClassifier** | Recent/old/uncertain classification and probe budget exhaustion |
| **ZipInspector** | Crafted ZIP fixtures for end-of-central-directory parsing and .app entry detection |

### 10.2 Integration Tests

| Scenario | Method |
|----------|--------|
| Full scan on real system | Manual — verify results make sense |
| Clean to Trash | Create temp files, clean, verify in Trash |
| Orphan detection accuracy | Uninstall a test app, verify leftovers detected |
| FDA detection | Test with and without FDA granted |
| Uninstall flow | Install a test app, uninstall via Broom, verify complete removal |

### 10.3 UI Tests

- `BroomUITests` target runs main-window smoke tests (sidebar navigation, scan buttons) via accessibility identifiers
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
