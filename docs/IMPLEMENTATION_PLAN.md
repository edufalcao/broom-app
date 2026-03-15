# Broom — Step-by-Step Implementation Plan

> **Version:** 1.0.0-draft
> **Date:** 2026-03-15
> **Target:** macOS 14.0+ (Sonoma)

---

## Overview

This document breaks the implementation into 15 incremental steps. Each step produces something runnable and testable. The steps are ordered so that foundational pieces come first and features build on each other.

**Estimated scope for MVP (Steps 1-13):** ~2 weeks of focused work.

---

## Step 1: Xcode Project & Desktop App Shell

**Goal:** App launches as a standard desktop app with a main window containing sidebar navigation and placeholder content. Dock icon visible.

### Tasks

1. Create new Xcode project:
   - macOS → App → SwiftUI → Product Name: "Broom"
   - Bundle Identifier: `com.broom.app`
   - Uncheck "Include Tests" (we'll add manually later)

2. Configure project settings:
   - Signing & Capabilities → Remove "App Sandbox"
   - Set Deployment Target to macOS 14.0
   - Architectures: Standard (Universal)

3. Replace `BroomApp.swift`:
   ```swift
   @main
   struct BroomApp: App {
       var body: some Scene {
           Window("Broom", id: "main") {
               MainWindow()
           }
           .defaultSize(width: 750, height: 520)
           .windowResizability(.contentMinSize)

           Settings {
               Text("Settings will go here")
                   .frame(width: 300, height: 200)
           }
       }
   }
   ```

4. Create `Views/MainWindow.swift`:
   ```swift
   struct MainWindow: View {
       @State private var selectedSection: SidebarSection = .cleaner

       enum SidebarSection: String, CaseIterable, Identifiable {
           case cleaner = "Clean"
           case uninstaller = "Apps"

           var id: String { rawValue }
           var icon: String {
               switch self {
               case .cleaner: return "magnifyingglass"
               case .uninstaller: return "shippingbox"
               }
           }
       }

       var body: some View {
           NavigationSplitView {
               List(SidebarSection.allCases, selection: $selectedSection) { section in
                   Label(section.rawValue, systemImage: section.icon)
               }
               .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
           } detail: {
               switch selectedSection {
               case .cleaner:
                   Text("System Cleaner — coming soon")
               case .uninstaller:
                   Text("App Uninstaller — coming soon")
               }
           }
       }
   }
   ```

5. Delete the default `ContentView.swift` — we won't use it.

6. Build & Run. Verify:
   - App launches with a standard window and Dock icon
   - Sidebar shows "Clean" and "Apps" sections
   - Clicking sidebar items switches the detail view
   - Cmd+Q quits the app
   - Cmd+, opens Settings window
   - Window can be resized, minimized, closed

### Files Changed
- `BroomApp.swift` (modified)
- `Views/MainWindow.swift`

---

## Step 2: Foundation Layer — Constants, Formatter, Logger

**Goal:** All scan target paths defined in one place. Size formatting works. Logging works.

### Tasks

1. Create `Utilities/Constants.swift`:
   - Define all scan target paths as static computed properties
   - Define protected bundle ID prefixes
   - Define Library subdirectories for orphan/app scanning
   - Group by category with MARK comments

2. Create `Utilities/SizeFormatter.swift`:
   - Wrapper around `ByteCountFormatter`
   - Static `format(_ bytes: Int64) -> String` method
   - Use `.file` count style (1000-based, like Finder)

3. Create `Utilities/Logger.swift`:
   - Thin wrapper around `os.Logger`
   - Subsystem: `com.broom.app`
   - Categories: `scanner`, `cleaner`, `orphan`, `uninstaller`, `ui`

4. Create unit test target:
   - Add `BroomTests` target to the project
   - Write `SizeFormatterTests.swift`:
     - Test 0 bytes → "Zero KB"
     - Test 1024 → "1 KB"
     - Test 1_500_000 → "1.5 MB"
     - Test 1_500_000_000 → "1.5 GB"

### Files Created
- `Utilities/Constants.swift`
- `Utilities/SizeFormatter.swift`
- `Utilities/Logger.swift`
- `BroomTests/SizeFormatterTests.swift`

---

## Step 3: Data Models

**Goal:** All data structures defined and testable.

### Tasks

1. Create `Models/CleanableItem.swift`
2. Create `Models/CleanCategory.swift`
3. Create `Models/ScanResult.swift`
4. Create `Models/OrphanedApp.swift` (with `OrphanConfidence` enum)
5. Create `Models/InstalledApp.swift`
6. Create `Models/CleanReport.swift`

7. Write `BroomTests/ModelTests.swift`:
   - Test `CleanCategory.totalSize` computed property
   - Test `CleanCategory.selectedSize` with mixed selection
   - Test `ScanResult.totalSize` aggregation
   - Test `OrphanedApp.totalSize` aggregation

### Files Created
- All 6 model files
- `BroomTests/ModelTests.swift`

---

## Step 4: FileScanner — System Caches Only

**Goal:** Scan `~/Library/Caches/` and display results in the main cleaner view.

### Tasks

1. Create `Services/FileScanner.swift`:
   - Declare as `actor`
   - Implement `directorySize(at: URL) -> Int64`
   - Implement `scanSystemCaches() async -> CleanCategory`
   - Implement `scanAll() async -> ScanResult` (only calls `scanSystemCaches` for now)

2. Create `ViewModels/ScanViewModel.swift`:
   - `@Observable` class
   - State enum: `.idle`, `.scanning`, `.results`, `.cleaning`, `.done`, `.error`
   - `startScan()` async method
   - `reset()` method

3. Create `Views/Cleaner/CleanerView.swift`:
   - Switch on `viewModel.state`
   - Idle state: "Scan System" button
   - Scanning state: `ProgressView()` (indeterminate for now)
   - Results state: show category name and total size

4. Wire `CleanerView` into `MainWindow.swift` as the detail view for the "Clean" sidebar section

5. Build & Run. Verify:
   - Select "Clean" in sidebar → shows idle state
   - Click "Scan System" → shows scanning state
   - After scan → shows "System Caches: X GB"
   - Size matches `du -sh ~/Library/Caches/` approximately

6. Write `BroomTests/FileScannerTests.swift`:
   - Create temp directory with known files
   - Test `directorySize()` accuracy
   - Test `scanSystemCaches()` returns non-empty category

### Files Created
- `Services/FileScanner.swift`
- `ViewModels/ScanViewModel.swift`
- `Views/Cleaner/CleanerView.swift`
- `BroomTests/FileScannerTests.swift`

---

## Step 5: Scan Results UI

**Goal:** Scan results show as a list of categories with sizes, icons, and toggles.

### Tasks

1. Create `Views/Components/CategoryRowView.swift`:
   - SF Symbol icon
   - Category name
   - Size label (right-aligned)
   - Toggle checkbox
   - Disclosure chevron for drilldown

2. Create `Views/Components/SizeLabel.swift`:
   - Takes `Int64` bytes, displays formatted size
   - Color-coded: red for > 1GB, orange for > 100MB, default otherwise

3. Create `Views/Cleaner/ScanResultsView.swift`:
   - Header: "Found X of junk" with total size prominently displayed
   - Scan duration label
   - `ScrollView` + `LazyVStack` of `CategoryRowView`
   - "Clean Selected" button at the bottom
   - "Re-scan" button
   - Selected size summary

4. Create `Views/Cleaner/IdleView.swift`:
   - "Scan System" button (`.borderedProminent`)
   - "Last scan: X ago" label (stored in `@AppStorage`)

5. Create `Views/Cleaner/ScanningView.swift`:
   - Indeterminate `ProgressView` (will make determinate in Step 6)
   - "Scanning..." label
   - "Cancel" button

6. Update `CleanerView.swift` to use these new views

7. Build & Run. Verify:
   - Scan shows real results with proper formatting
   - Sizes are human-readable (KB, MB, GB)
   - Checkboxes toggle
   - "Selected: X" updates when toggling

### Files Created
- `Views/Components/CategoryRowView.swift`
- `Views/Components/SizeLabel.swift`
- `Views/Cleaner/ScanResultsView.swift`
- `Views/Cleaner/IdleView.swift`
- `Views/Cleaner/ScanningView.swift`

---

## Step 6: Full Scan — All Categories

**Goal:** Scanner covers all junk categories. Progress reporting works.

### Tasks

1. Add to `FileScanner.swift`:
   - `scanBrowserCaches() async -> CleanCategory` — Chrome, Firefox, Safari, Arc, Brave, Edge
   - `scanLogs() async -> CleanCategory` — user and system logs, crash reports
   - `scanTempFiles() async -> CleanCategory` — $TMPDIR, /tmp (files > 24h old)
   - `scanXcode() async -> CleanCategory?` — DerivedData, Archives (nil if not present)
   - `scanDeveloperCaches() async -> CleanCategory` — SPM, CocoaPods, Homebrew, npm, Yarn, pip
   - `scanMailAttachments() async -> CleanCategory?` — Mail Downloads (nil if no FDA)
   - `scanDSStores() async -> CleanCategory` — recursive .DS_Store search

2. Update `scanAll()` to call all category scanners with `async let` for parallelism

3. Add progress reporting:
   - Define `ScanProgress` enum: `.scanning(category: String, progress: Double)`, `.complete(ScanResult)`
   - Change `scanAll()` to return `AsyncStream<ScanProgress>`
   - Update `ScanViewModel` to consume the stream and update progress

4. Update `ScanningView` to show:
   - Determinate progress bar
   - Current category name
   - Running total of junk found

5. Create `Services/PermissionChecker.swift`:
   - `hasFullDiskAccess` static property
   - `requestFullDiskAccess()` opens System Settings

6. Create `Views/Components/PermissionBanner.swift`:
   - Warning banner when FDA not granted
   - "Grant Access" button
   - Explain what additional cleaning is available with FDA

7. Show banner in `IdleView` (within the cleaner section) when FDA not granted

8. Build & Run. Verify:
   - All categories scan correctly
   - Progress bar advances smoothly
   - Categories that don't exist (e.g., Xcode on non-dev machine) are omitted
   - FDA banner appears/disappears correctly

### Files Modified
- `Services/FileScanner.swift` (major expansion)
- `ViewModels/ScanViewModel.swift`

### Files Created
- `Services/PermissionChecker.swift`
- `Views/Components/PermissionBanner.swift`

---

## Step 7: Category Detail & Item Selection

**Goal:** User can drill into a category to see and toggle individual items.

### Tasks

1. Create `Views/Cleaner/CategoryDetailView.swift`:
   - Navigation-style: back button with category name
   - "Select All" toggle at top
   - Scrollable list of individual items
   - Each item shows: checkbox, name (last path component), size, modified date
   - Selected size summary at bottom

2. Add navigation to `ScanResultsView`:
   - Clicking a category row (or chevron) pushes `CategoryDetailView`
   - Use `NavigationStack` within the cleaner detail area

3. Update `ScanViewModel`:
   - `toggleCategory(_ id: UUID)` — toggles all items in category
   - `toggleItem(_ itemId: UUID, in categoryId: UUID)` — toggles single item
   - `selectAll()` / `deselectAll()`
   - These all mutate the `scanResult` in place

4. Build & Run. Verify:
   - Tapping a category shows its items
   - Items can be individually toggled
   - "Select All" works
   - Back button returns to results
   - Selected size updates across views

### Files Created
- `Views/Cleaner/CategoryDetailView.swift`

### Files Modified
- `Views/Cleaner/ScanResultsView.swift`
- `ViewModels/ScanViewModel.swift`

---

## Step 8: FileCleaner — Clean to Trash

**Goal:** "Clean Selected" actually deletes files (moves to Trash) with confirmation and progress.

### Tasks

1. Create `Utilities/SafeDelete.swift`:
   - Wrapper around `FileManager.trashItem(at:resultingItemURL:)`
   - Returns success/failure with error details
   - Logs every operation via `os.Logger`

2. Create `Utilities/ExclusionList.swift`:
   - Hardcoded exclusions (see PRD §2.1.3)
   - Method: `isExcluded(_ path: URL) -> Bool`
   - Method: `isProtectedBundleID(_ id: String) -> Bool`

3. Create `Services/FileCleaner.swift`:
   - Actor
   - `clean(items:moveToTrash:)` method
   - Progress reporting via AsyncStream
   - Returns `CleanReport`

4. Create `Services/RunningAppDetector.swift`:
   - Static method to get running bundle IDs
   - Used to warn before cleaning running app caches

5. Create `Views/Cleaner/CleanProgressView.swift`:
   - Determinate progress bar
   - Current item being cleaned
   - Items cleaned count / total

6. Create `Views/Cleaner/CleanDoneView.swift`:
   - Checkmark icon
   - "Freed X of disk space"
   - Error summary if partial failure
   - "Scan Again" button

7. Add confirmation dialog:
   - Before cleaning, show `.confirmationDialog` or `NSAlert`
   - "Clean X items totaling Y? Files will be moved to Trash."
   - "Clean" (destructive) and "Cancel" buttons

8. Wire `ScanViewModel.startClean()`:
   - Check for running apps, warn if any
   - Show confirmation
   - Execute clean
   - Report results

9. Build & Run. Verify:
   - Confirmation dialog appears
   - Progress bar shows during cleaning
   - Files actually appear in Trash
   - Freed space is reported
   - Recovering from Trash restores files
   - Errors (permission denied) are handled gracefully

### Files Created
- `Utilities/SafeDelete.swift`
- `Utilities/ExclusionList.swift`
- `Services/FileCleaner.swift`
- `Services/RunningAppDetector.swift`
- `Views/Cleaner/CleanProgressView.swift`
- `Views/Cleaner/CleanDoneView.swift`

### Files Modified
- `ViewModels/ScanViewModel.swift`

---

## Step 9: Orphan Detection

**Goal:** Detect files left behind by uninstalled apps and show them in scan results.

### Tasks

1. Create `Services/AppInventory.swift`:
   - Actor
   - `installedBundleIdentifiers() async -> Set<String>`
   - Enumerate `/Applications/` and `~/Applications/`
   - Parse `Info.plist` → `CFBundleIdentifier`
   - Optional: supplement with Spotlight `NSMetadataQuery`

2. Create `Utilities/BundleIDMatcher.swift`:
   - `matches(directoryName: String, againstInstalled: Set<String>) -> Bool`
   - Direct match
   - Reverse-domain prefix match
   - Normalized name match (lowercase, remove hyphens/dots)
   - Substring containment

3. Create `Services/OrphanDetector.swift`:
   - Actor
   - `detectOrphans() async -> [OrphanedApp]`
   - Scan Application Support, Caches, Preferences, Containers, Group Containers, Saved Application State, WebKit, HTTPStorages
   - Filter against installed apps
   - Filter out protected prefixes
   - Group by inferred app name
   - Assign confidence scores
   - Sort by total size

4. Create `Views/Components/ConfidenceBadge.swift`:
   - Green checkmark for high confidence
   - Yellow circle for medium
   - Orange warning for low

5. Update `Views/Cleaner/ScanResultsView.swift`:
   - Add orphan section below regular categories
   - Section header: "App Leftovers"
   - Each orphan shows: app name, confidence badge, total size, toggle
   - Defaults to unselected
   - Expandable to show individual locations

6. Update `ScanViewModel`:
   - Include orphan detection in `startScan()`
   - Add orphan results to `ScanResult`
   - Add `toggleOrphan(_ id: UUID)` and `toggleOrphanLocation(_ itemId: UUID, in orphanId: UUID)` helpers

7. Update models for orphan selection:
   - `OrphanedApp`: add computed selection helpers (`selectedSize`, `selectedCount`, `isSelected`)
   - `ScanResult`: include orphan sizes/counts in aggregate totals

8. Build & Run. Verify:
   - Orphan section appears in scan results within the cleaner view
   - Known uninstalled apps are detected
   - System/Apple entries are not flagged
   - Confidence badges show correctly
   - Orphans default to unselected

9. Write `BroomTests/BundleIDMatcherTests.swift`:
   - Test exact match
   - Test prefix match
   - Test normalized match
   - Test no false positives for Apple bundle IDs

10. Write `BroomTests/OrphanDetectorTests.swift`:
   - Test with mock AppInventory
   - Test protected prefix filtering
   - Test grouping logic

### Files Created
- `Services/AppInventory.swift`
- `Utilities/BundleIDMatcher.swift`
- `Services/OrphanDetector.swift`
- `Views/Components/ConfidenceBadge.swift`
- `BroomTests/BundleIDMatcherTests.swift`
- `BroomTests/OrphanDetectorTests.swift`

### Files Modified
- `Views/Cleaner/ScanResultsView.swift`
- `ViewModels/ScanViewModel.swift`
- `Models/ScanResult.swift`
- `Models/OrphanedApp.swift`

---

## Step 10: App Uninstaller — App List & Detail

**Goal:** User can browse installed apps with sizes and see all associated files.

### Tasks

1. Expand `Services/AppInventory.swift`:
   - `loadAllApps() async -> [InstalledApp]`
   - For each app: name, bundle ID, version, icon, bundle size, associated files
   - `findAssociatedFiles(for bundleID: String, appName: String) async -> [CleanableItem]`
   - Search all Library subdirectories for matching entries
   - `appLastUsedDate(at: URL) -> Date?` using Spotlight metadata

2. Create `Utilities/AppIconLoader.swift`:
   - `loadIcon(for app: URL) -> NSImage`
   - Uses `NSWorkspace.shared.icon(forFile:)` — simple and reliable

3. Create `ViewModels/UninstallerViewModel.swift`:
   - `@Observable` class
   - State enum: `.loading`, `.ready`, `.preparingUninstall`, `.confirming`, `.uninstalling`, `.done`
   - `loadApps()` async
   - `selectApp(_ app)` async — loads associated files on demand
   - Search text filtering
   - Sort order (name, size, last used)

4. Create `Views/Uninstaller/UninstallerView.swift`:
   - Main content view for the "Apps" sidebar section
   - Nested `HSplitView` with app list (left) and detail (right)

5. Create `Views/Uninstaller/AppListView.swift`:
   - Search bar at top
   - Sort controls
   - Scrollable list of `AppRowView`
   - Selection highlight

6. Create `Views/Uninstaller/AppRowView.swift`:
   - App icon (32x32)
   - App name
   - Total size (right-aligned)
   - Visual indicator for system/protected apps

7. Create `Views/Uninstaller/AppDetailView.swift`:
   - Large app icon (64x64)
   - App name, version, last used date
   - Bundle ID (dimmed)
   - List of associated files with:
     - Location name (e.g., "Application Support", "Caches")
     - Path
     - Size
     - Toggle checkbox
   - Total selected size
   - "Uninstall" button (`.borderedProminent`, `.tint(.red)`)
   - Protected apps: button disabled with explanation

8. Create `Views/Components/AppIconView.swift`:
   - Displays `NSImage` in SwiftUI via `Image(nsImage:)`
   - Fallback to generic app icon

9. Wire `UninstallerView` into `MainWindow.swift` as the detail view for the "Apps" sidebar section

10. Build & Run. Verify:
    - Clicking "Apps" in sidebar shows the uninstaller view
    - All installed apps show with icons and sizes
    - Selecting an app shows its associated files
    - Search filters correctly
    - Sort works for name, size, last used
    - System/Apple apps are marked as protected

### Files Created
- `Utilities/AppIconLoader.swift`
- `ViewModels/UninstallerViewModel.swift`
- `Views/Uninstaller/UninstallerView.swift`
- `Views/Uninstaller/AppListView.swift`
- `Views/Uninstaller/AppRowView.swift`
- `Views/Uninstaller/AppDetailView.swift`
- `Views/Components/AppIconView.swift`

### Files Modified
- `Services/AppInventory.swift`
- `Views/MainWindow.swift`

---

## Step 11: App Uninstaller — Uninstall Flow

**Goal:** User can fully uninstall an app (bundle + all Library files) with confirmation and safety checks.

### Tasks

1. Create `Services/AppUninstaller.swift`:
   - Actor
   - `prepareUninstall(app: InstalledApp) async -> UninstallPlan`
   - `executeUninstall(plan:moveToTrash:) -> AsyncStream<UninstallProgress>`
   - `isAppRunning(bundleIdentifier:) -> Bool`
   - `terminateApp(bundleIdentifier:) async -> Bool`
   - Deletion order: Library files first, .app bundle last

2. Define `UninstallPlan` model:
   - App reference
   - All files to remove (with individual toggles)
   - Total size
   - Running status
   - Protected status

3. Create `Views/Uninstaller/UninstallConfirmView.swift`:
   - Alert/sheet showing:
     - App name and icon
     - Number of files and total size
     - Warning if app is running (with "Quit and Uninstall" option)
     - "Move to Trash" (default) vs "Delete Permanently" choice
     - "Uninstall" (destructive) and "Cancel" buttons

4. Add uninstall progress to `AppDetailView`:
   - Progress bar during uninstall
   - Item-by-item status
   - Completion summary

5. Update `UninstallerViewModel`:
   - `prepareUninstall()` — builds the plan, checks running status
   - `confirmUninstall()` — executes the plan
   - Handle running app: offer to quit
   - Handle force-quit: only on explicit user action
   - Update app list after successful uninstall (remove the app)

6. Build & Run. Verify:
   - Selecting uninstall shows confirmation with full file list
   - Running apps: warning shown, option to quit
   - Uninstall moves all files to Trash
   - App disappears from the list after uninstall
   - Can recover from Trash
   - Protected apps cannot be uninstalled

### Files Created
- `Services/AppUninstaller.swift`
- `Views/Uninstaller/UninstallConfirmView.swift`

### Files Modified
- `ViewModels/UninstallerViewModel.swift`
- `Views/Uninstaller/AppDetailView.swift`

---

## Step 12: Drag-and-Drop Uninstall

**Goal:** User can drag a .app from Finder onto the app window or Dock icon to uninstall it.

### Tasks

1. Add drop zone to the uninstaller view:
   - Add a drop zone overlay in `UninstallerView`
   - "Drop a .app here to uninstall it"
   - Uses `.onDrop(of:)` modifier
   - On drop: parse URL, select the app, show uninstall confirmation

2. Add Dock icon drop support:
   - Implement `NSApplicationDelegate` method `application(_:open:)` to handle `.app` files dropped onto the Dock icon
   - On Dock drop: switch sidebar to "Apps" section and pre-select the dropped app
   - Wire delegate via `@NSApplicationDelegateAdaptor`

3. Implement the drop handling:
   - Add `.onDrop(of: [.fileURL])` to `UninstallerView`
   - Validate that dropped item is a `.app` bundle
   - Call `UninstallerViewModel.handleAppDrop(url:)`
   - Auto-select the app and show detail view

4. Build & Run. Verify:
   - Dragging a .app onto the uninstaller view highlights the drop zone
   - Dropping selects the app and shows its detail
   - Dropping a .app onto the Dock icon switches to the uninstaller and selects the app
   - Dragging non-.app files shows error or is ignored
   - Dragging system apps shows protected warning

### Files Modified
- `Views/Uninstaller/UninstallerView.swift`
- `ViewModels/UninstallerViewModel.swift`
- `BroomApp.swift` (add NSApplicationDelegateAdaptor)

---

## Step 13: Settings

**Goal:** Preferences window with General, Cleaning, Safe List, and About tabs.

### Tasks

1. Create `Views/Settings/SettingsView.swift`:
   - `TabView` with four tabs
   - Uses `.tabViewStyle(.automatic)` for native macOS settings look

2. Create `Views/Settings/GeneralSettingsView.swift`:
   - Launch at login toggle (using `SMAppService.mainApp`)
   - Notification preferences

3. Create `Views/Settings/CleaningSettingsView.swift`:
   - Default delete method: Trash vs Permanent (picker)
   - Skip running app caches (toggle, default: on)
   - Minimum temp file age (stepper: 1h, 6h, 12h, 24h, 48h, 7d)
   - Show developer caches in scan (toggle, default: on)
   - .DS_Store scanning (toggle, default: on)

4. Create `Views/Settings/SafeListSettingsView.swift`:
   - Table/list of excluded paths and bundle IDs
   - Add button (shows file picker for paths, text field for bundle IDs)
   - Remove button
   - Import/Export as JSON
   - Store in `~/Library/Application Support/Broom/safelist.json`

5. Create `Views/Settings/AboutSettingsView.swift`:
   - App icon and name
   - Version number from bundle
   - "View on GitHub" link
   - License: MIT
   - "Made with ❤️ by Eduardo"

6. Create `ViewModels/SettingsViewModel.swift`:
   - Uses `@AppStorage` for simple preferences
   - Manages safe list file I/O
   - Handles `SMAppService` for launch at login

7. Wire settings access into the app shell:
   - `Cmd+,` opens the `Settings` scene
   - Add a toolbar button / affordance that opens Settings from the main window

8. Wire settings into scan/clean behavior:
   - `FileScanner`: respect "show developer caches" and safe list
   - `FileCleaner`: respect "default delete method"
   - `RunningAppDetector`: respect "skip running app caches"

9. Build & Run. Verify:
   - Settings accessible via Cmd+, and the main window toolbar/gear affordance
   - All toggles persist across app restarts
   - Launch at login works
   - Safe list entries are respected during scan
   - Delete method preference is respected during clean

### Files Created
- `Views/Settings/SettingsView.swift`
- `Views/Settings/GeneralSettingsView.swift`
- `Views/Settings/CleaningSettingsView.swift`
- `Views/Settings/SafeListSettingsView.swift`
- `Views/Settings/AboutSettingsView.swift`
- `ViewModels/SettingsViewModel.swift`

### Files Modified
- `Services/FileScanner.swift`
- `Services/FileCleaner.swift`
- `Utilities/ExclusionList.swift`

---

## Step 14: Polish & Edge Cases

**Goal:** Handle edge cases, improve UX, add finishing touches.

### Tasks

1. **Empty states:**
   - Create `Views/Components/EmptyStateView.swift`
   - "No junk found! Your system is clean." (when scan finds nothing)
   - "No orphaned app files detected." (when no orphans)
   - "No apps found." (when uninstaller list is empty — shouldn't happen)

2. **Error handling hardening:**
   - Wrap all `FileManager` calls in do/catch
   - Show user-friendly errors, not raw system messages
   - "Permission denied" → suggest granting Full Disk Access
   - "File not found" → skip silently (race condition)
   - "Disk full" → warn user

3. **Running app warnings:**
   - Before cleaning, check if any selected cache belongs to a running app
   - Show warning: "Chrome is running. Cleaning its cache may cause issues. Quit Chrome first?"
   - Option to skip running app caches or proceed anyway

4. **Last scan timestamp:**
   - Store in `@AppStorage("lastScanDate")`
   - Display in `IdleView`: "Last scan: 2 hours ago" / "Never scanned"
   - Use `RelativeDateTimeFormatter` for natural language

5. **Keyboard shortcuts:**
   - Cmd+Shift+S → Start scan
   - Cmd+, → Open Settings (handled by SwiftUI)
   - Cmd+1 → Switch to Cleaner section
   - Cmd+2 → Switch to Apps section
   - Cmd+Q → Quit
   - Cmd+W → Close window

6. **Notifications:**
   - After background scan (if enabled): "Broom found X GB of junk files."
   - After clean: "Freed X GB of disk space."
   - Request notification permission on first use
   - Uses `UserNotifications` framework

7. **Dock icon badge:**
   - Show badge count or size when junk is found after a scan
   - Clear badge after cleaning

8. **Accessibility:**
   - All interactive elements have accessibility labels
   - VoiceOver compatible
   - Keyboard navigable

9. **Edge case testing:**
   - Test with no ~/Library/Caches/ (fresh install)
   - Test with FDA not granted
   - Test with thousands of cache entries (performance)
   - Test cleaning while Finder has Trash open
   - Test with symlinks in Library directories
   - Test with very long path names
   - Test window at minimum size — ensure no content clipping
   - Test sidebar navigation during active scan/clean

### Files Created
- `Views/Components/EmptyStateView.swift`

### Files Modified
- Multiple files across Views, ViewModels, and Services

---

## Step 15: Packaging & Distribution

**Goal:** Create distributable DMG, set up CI/CD, write README.

### Tasks

1. **App icon:**
   - Design a simple broom or leaf icon
   - Create all required sizes in `Assets.xcassets/AppIcon.appiconset/`
   - Alternatively: use an SF Symbol as a placeholder and commission an icon later

2. **DMG creation:**
   - Install `create-dmg`: `brew install create-dmg`
   - Create a build script `scripts/build-dmg.sh`:
     ```bash
     #!/bin/bash
     set -e
     xcodebuild -scheme Broom -configuration Release -archivePath build/Broom.xcarchive archive
     xcodebuild -exportArchive -archivePath build/Broom.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
     create-dmg --volname "Broom" --window-size 600 400 --icon "Broom.app" 150 190 --app-drop-link 450 190 "Broom.dmg" "build/Broom.app"
     ```

3. **Code signing (optional for initial release):**
   - If Apple Developer account available:
     - Sign with "Developer ID Application" certificate
     - Notarize with `xcrun notarytool submit`
   - If not: instruct users to right-click → Open on first launch
   - Create `scripts/notarize.sh`

4. **GitHub Actions CI:**
   - Create `.github/workflows/build.yml`:
     - Trigger: push to `main`, pull requests
     - Build with `xcodebuild`
     - Run tests
   - Create `.github/workflows/release.yml`:
     - Trigger: tag push `v*`
     - Build universal binary
     - Create DMG
     - (Optional) Notarize
     - Create GitHub Release with DMG asset

5. **Repository setup:**
   - `README.md`: description, screenshots, install instructions, build instructions
   - `LICENSE`: MIT
   - `CONTRIBUTING.md`: how to contribute
   - `CHANGELOG.md`: version history
   - `.swiftlint.yml`: baseline lint rules for contributors and CI
   - `.github/ISSUE_TEMPLATE/bug_report.md`
   - `.github/ISSUE_TEMPLATE/feature_request.md`
   - `.gitignore`: Xcode, macOS, Swift

6. **Homebrew cask (post-launch):**
   - Create `homebrew-broom` tap repository
   - Write cask formula
   - Submit to homebrew-cask (after gaining traction)

### Files Created
- `scripts/build-dmg.sh`
- `scripts/notarize.sh`
- `.github/workflows/build.yml`
- `.github/workflows/release.yml`
- `README.md`
- `LICENSE`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.gitignore`
- `ExportOptions.plist`

---

## Implementation Summary

### File Count by Step

| Step | New Files | Modified Files | Focus |
|------|-----------|----------------|-------|
| 1 | 1 | 1 | Project setup |
| 2 | 4 | 0 | Foundation utilities |
| 3 | 7 | 0 | Data models |
| 4 | 4 | 1 | Core scanner + basic UI |
| 5 | 5 | 1 | Results UI |
| 6 | 2 | 2 | Full scan + permissions |
| 7 | 1 | 2 | Category drill-down |
| 8 | 6 | 1 | File cleaning |
| 9 | 6 | 3 | Orphan detection |
| 10 | 7 | 2 | App uninstaller UI |
| 11 | 2 | 2 | Uninstall flow |
| 12 | 0 | 3 | Drag-and-drop |
| 13 | 6 | 3 | Settings |
| 14 | 1 | ~10 | Polish |
| 15 | ~12 | 0 | Packaging |
| **Total** | **~64** | **~31** | |

### Critical Path

```
Step 1 → Step 2 → Step 3 → Step 4 → Step 5 → Step 6 → Step 7 → Step 8
                                                                    ↓
                                          Step 10 ← Step 9 ← ──────┘
                                            ↓
                              Step 12 ← Step 11
                                            ↓
                              Step 14 ← Step 13
                                            ↓
                                         Step 15
```

Steps 9 (orphans) and 10 (uninstaller) share `AppInventory` — implement Step 9 first since it exercises the service, then Step 10 expands it.
