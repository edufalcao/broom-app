# Broom — Uninstall & Orphan Hardening Plan

> **Date:** 2026-03-16
> **Status:** Proposed
> **Target:** Post-1.0 baseline hardening

---

## Overview

This plan covers two related improvements to Broom's cleaner and uninstaller:

1. Explicit app uninstalls should remove more of the app's real footprint.
2. Generic "App Leftovers" detection should become materially more conservative.

The guiding rule is simple:

- **Explicit uninstall:** exhaustive within safe, validated boundaries.
- **Generic leftover detection:** conservative by default. If an item may still belong to a live or recoverable app, do not list it.

This plan borrows the useful product and safety ideas from Mole while keeping Broom aligned with its native macOS app model and current product scope.

---

## Goals

- Improve uninstall completeness so selected app removals leave fewer residual files, services, and metadata artifacts behind.
- Reduce false positives in orphan detection, especially for files that may still be in use, recently used, or tied to non-standard installs.
- Move safety enforcement closer to the final delete boundary instead of relying only on pre-selection filters.
- Expand automated test coverage around uninstall discovery, orphan suppression, and destructive-operation guardrails.

## Non-Goals

- Add Mole-style system optimization features.
- Add generic startup-item management beyond app-specific uninstall cleanup.
- Aggressively clean ambiguous user data from generic orphan scans.
- Change the product thesis from "trustworthy cleaner" to "all-in-one system utility."

---

## Current Gaps

### Uninstall completeness

- Installed-app discovery is centered on `/Applications` and `~/Applications`, with Spotlight as a supplement.
- Associated-file discovery does not yet use installation receipts, login items, privileged helpers, or broader plugin/framework patterns.
- Uninstall execution removes selected paths, but does not explicitly unregister LaunchServices metadata or clean login items after removal.

### Orphan detection accuracy

- `OrphanDetector` suppresses candidates only when they match currently installed bundle IDs.
- Receipt and Spotlight signals currently affect confidence scoring, but do not suppress a candidate from being listed.
- Matching is permissive enough that name-based and prefix-based heuristics can still surface ambiguous leftovers.
- There is no stale-age threshold for generic orphan listing.
- There is no dedicated "never orphan list" for sensitive or high-risk app data families.

### Safety enforcement

- `SafeDelete` performs file operations directly and logs outcomes, but does not act as a final path-validation and protection boundary.
- Cleaner and uninstall flows rely primarily on earlier filtering layers to prevent unsafe deletion attempts.

---

## Success Criteria

### User-facing

- Uninstalling a typical third-party app removes its app bundle, common Library data, related agents/helpers, and known receipt-backed artifacts when those paths are still present and safe.
- Generic leftover detection no longer surfaces items for apps that are still installed, currently running, recently modified, or plausibly active in non-standard locations.
- When Broom is uncertain, it suppresses the item instead of showing a low-confidence false positive.

### Engineering

- Destructive operations pass through a final validation layer.
- New uninstall/orphan rules are covered by unit tests and fixture-based integration tests.
- The orphan scanner remains fast enough for interactive use despite stricter suppression checks.

---

## Design Principles

### 1. Separate uninstall logic from orphan logic

- Explicit uninstall can use broader matching and app-specific heuristics because the user selected a concrete app.
- Generic orphan cleanup must use narrower matching and stronger suppression checks because the app is inferred, not chosen.

### 2. Suppression beats confidence

- Installed, running, recently modified, or otherwise plausible app data should be removed from orphan results entirely.
- Confidence should help rank remaining results, not justify showing risky ones.

### 3. Validate again at delete time

- Path safety, symlink handling, protected prefixes, and sensitive-data protections should be enforced immediately before file operations.

### 4. Prefer structured discovery over ad hoc string matching

- Artifact discovery should be organized into typed providers with explicit scopes and tests.
- New heuristics should be opt-in by context and easy to disable when they create ambiguity.

---

## Workstreams

The work is split into seven workstreams that can be delivered incrementally.

### Workstream 1: Installed App Inventory Hardening

### Objective

Reduce false orphan classifications by improving the picture of what is still installed or active on the machine.

### Changes

- Expand installed-app discovery roots to include:
  - `/System/Applications`
  - Homebrew Caskroom paths
  - Setapp application paths
- Add a lightweight running-app bundle-ID snapshot for orphan suppression.
- Add LaunchAgent/LaunchDaemon label collection for suppression, not cleanup.
- Normalize all installed/running identifiers to a single canonical lowercased representation.

### Deliverables

- `AppInventory` gains broader install-source discovery.
- A reusable `InstalledAppSnapshot` value is available to the orphan detector.
- Tests cover standard, non-standard, and duplicated install locations.

---

### Workstream 2: Explicit Uninstall Artifact Planning

### Objective

Make explicit app uninstall closer to "remove everything relevant that is safe to remove."

### Changes

- Replace the current single-pass associated-file finder with artifact providers such as:
  - user Library artifacts
  - preferences and ByHost plists
  - group containers and app scripts
  - web storage, cookies, saved state, logs
  - launch agents/daemons
  - login items
  - privileged helpers
  - receipt-backed system artifacts
  - diagnostic/crash reports for the app executable
- Add app-name variant generation for uninstall only:
  - no-space
  - hyphenated
  - underscored
  - lowercase variants
  - version/channel-trimmed base names where safe
- Keep provider output deduplicated and annotated by source.

### Deliverables

- New uninstall artifact planner service.
- Richer uninstall preview grouped by artifact source.
- Tests for naming variants, receipts, and system-level companion files.

---

### Workstream 3: Post-Uninstall Metadata Cleanup

### Objective

Reduce the "app is gone but still feels present" problem after uninstall.

### Changes

- Remove app-specific login items during explicit uninstall.
- Unload matching launch agents and daemons before deleting their files.
- Unregister the removed app bundle from LaunchServices.
- Refresh LaunchServices metadata after uninstall with bounded, failure-tolerant behavior.

### Deliverables

- `AppUninstaller` performs pre-delete and post-delete metadata cleanup.
- Uninstall reporting includes which metadata cleanup steps ran or were skipped.
- Tests cover bounded failure behavior and protected-app skips.

---

### Workstream 4: Conservative Orphan Detection Rewrite

### Objective

Only show leftovers when Broom has strong reason to believe they belong to an uninstalled and inactive app.

### Changes

- Rewrite orphan detection around suppression checks in this order:
  - protected path or protected data family
  - installed app match from expanded inventory
  - running app match
  - LaunchAgent/LaunchDaemon activity match
  - Spotlight / LaunchServices existence match
  - recent modification threshold
  - minimum size threshold
- Introduce a configurable but opinionated stale-age rule for generic orphan candidates.
  - default: 30 days
  - generic orphan scan should not list freshly modified items
- Restrict generic orphan listing to stricter path patterns:
  - reverse-DNS bundle-style directories
  - `.savedState`
  - `.binarycookies`
  - tightly scoped app storage locations
- Keep name-only heuristics out of generic orphan listing by default.
- Reserve broader fuzzy matching for explicit uninstall only.

### Deliverables

- New suppression-first orphan engine.
- Fewer orphan results, but with higher trust.
- Tests for stale-age, non-standard installs, running apps, and suppression precedence.

---

### Workstream 5: Sensitive Data & Protection Policy

### Objective

Ensure risky data categories are never surfaced as generic leftovers unless the user explicitly uninstalls the corresponding app.

### Changes

- Add a dedicated protected-data policy for generic orphan cleanup, covering categories such as:
  - password managers and keychain-adjacent data
  - VPN / proxy tooling
  - browser cookies and history stores
  - AI model and assistant app data
  - iCloud-synced or cloud-backed user data
  - user-owned automation and login-item configuration
- Keep explicit uninstall allowed for user-selected apps, but route those deletions through stronger preview and final validation.

### Deliverables

- New protected-data matcher used by orphan detection and final delete validation.
- Tests ensuring generic orphan scans do not expose protected families.

---

### Workstream 6: Final Deletion Guard

### Objective

Enforce safety at the last responsible moment.

### Changes

- Introduce a delete-policy layer in front of `trashItem` / `removeItem`.
- Validate:
  - absolute path rules
  - protected prefixes
  - symlink handling
  - protected-data categories
  - uninstall-mode exceptions vs generic-clean mode
- Return structured failure reasons so UI and tests can distinguish:
  - protected
  - missing
  - permission denied
  - unsafe symlink
  - system-protected

### Deliverables

- `SafeDelete` becomes a policy-aware execution boundary.
- Cleaner and uninstall flows consume structured delete results.
- Tests cover blocked paths and symlink edge cases.

---

### Workstream 7: UI and Preference Updates

### Objective

Expose the new behavior clearly without making the product feel more complex.

### Changes

- Update uninstall preview to show artifact groups with clearer labels:
  - App Bundle
  - User Data
  - Caches
  - Web Data
  - Launch Items
  - Helpers
  - Receipts / System Support
- Add orphan-results messaging that explains the conservative policy:
  - "Only stale, high-confidence leftovers are shown."
- Add a preference for orphan stale age if we decide that needs user control.
- Keep low-confidence orphan UI secondary; do not encourage selection.

### Deliverables

- Improved uninstall preview organization.
- Clearer orphan results messaging.
- Updated docs and release notes describing stricter orphan policy.

---

## Recommended Implementation Order

1. Installed app inventory hardening.
2. Conservative orphan detector rewrite.
3. Explicit uninstall artifact planner.
4. Post-uninstall metadata cleanup.
5. Final deletion guard.
6. UI and preference updates.
7. Documentation and release note updates.

This order reduces false positives first, then expands explicit uninstall completeness, then hardens execution boundaries.

---

## Detailed Task Breakdown

This section turns the workstreams into a concrete implementation checklist with likely file touchpoints.

### Phase 1: Shared Inventory and Matching Primitives

**Primary files**

- `Broom/Utilities/Constants.swift`
- `Broom/Services/ServiceProtocols.swift`
- `Broom/Services/AppInventory.swift`
- `Broom/Utilities/BundleIDMatcher.swift`
- `BroomTests/AppInventoryTests.swift`
- `BroomTests/BundleIDMatcherTests.swift`

**Tasks**

- Add new application roots and support locations to `Constants`:
  - `/System/Applications`
  - `/opt/homebrew/Caskroom`
  - `/usr/local/Caskroom`
  - `~/Library/Application Support/Setapp/Applications`
- Add an installed-app snapshot type that captures:
  - installed bundle IDs
  - installed app URLs
  - running bundle IDs
  - known launch item labels
- Extend `AppInventory` to build that snapshot from disk, Spotlight, and currently running apps.
- Deduplicate install records across standard roots, Spotlight, and non-standard roots.
- Split bundle matching into separate APIs:
  - strict orphan-safe matching
  - broader uninstall-only matching
- Add tests for:
  - duplicate app paths
  - standard vs non-standard installs
  - Spotlight-only discovery
  - running-app suppression inputs

**Exit criteria**

- Broom can reliably answer "is this app still installed or active?" without depending on loose string matching.

### Phase 2: Conservative Orphan Engine

**Primary files**

- `Broom/Services/OrphanDetector.swift`
- `Broom/Utilities/AppPreferences.swift`
- `Broom/Utilities/Constants.swift`
- `Broom/Utilities/ExclusionList.swift`
- `Broom/Utilities/BundleIDMatcher.swift`
- `Broom/Models/OrphanedApp.swift`
- `BroomTests/OrphanDetectorTests.swift`
- `BroomTests/OrphanCategoryTests.swift`

**Tasks**

- Add a stale-age preference/default for generic orphan detection.
- Introduce a provisional protected-data matcher interface for orphan suppression.
  - In Phase 2, this can be backed by current exclusions plus a small seed set of clearly protected families.
  - Do not block the orphan rewrite on the final Phase 5 policy surface.
- Introduce a suppression-first flow in `OrphanDetector`:
  - protected path check
  - protected data-family check
  - installed app snapshot match
  - running app match
  - launch item match
  - Spotlight / LaunchServices existence signal
  - recent modification threshold
  - minimum-size threshold
- Change receipt and Spotlight signals from confidence inputs into suppression inputs where appropriate.
- Restrict generic orphan candidates to stricter patterns:
  - reverse-domain bundle-style entries
  - `.savedState`
  - `.binarycookies`
  - explicitly scoped storage folders
- Remove broad name-only heuristics from generic orphan listing.
- Keep confidence scoring only for already-surviving candidates.
- Add tests for:
  - recent files being suppressed
  - running apps being suppressed
  - Caskroom / Setapp installs suppressing leftovers
  - low-signal name-only leftovers not being listed
  - sensitive data families never being listed

**Exit criteria**

- Generic orphan results are materially smaller but much more trustworthy.
- The orphan engine can call a stable protected-data matcher without taking a hard dependency on the full Phase 5 implementation.

### Phase 3: Explicit Uninstall Artifact Planner

**Primary files**

- `Broom/Services/AppInventory.swift`
- `Broom/Services/AppUninstaller.swift`
- `Broom/Services/ServiceProtocols.swift`
- `Broom/Models/InstalledApp.swift`
- `Broom/Models/CleanableItem.swift`
- `BroomTests/AppInventoryTests.swift`
- `BroomTests/AppUninstallerTests.swift`

**Likely new files**

- `Broom/Services/UninstallArtifactPlanner.swift`
- `Broom/Models/UninstallArtifactSource.swift`

**Tasks**

- Extract uninstall artifact discovery into its own planner instead of overloading generic associated-file lookup.
- Add artifact providers for:
  - user Library folders
  - preferences and ByHost plists
  - group containers
  - app scripts
  - web storage and cookies
  - saved application state
  - logs and diagnostic reports
  - launch agents and daemons
  - privileged helper tools
  - receipt-backed system files
- Add uninstall-only name variant generation:
  - space-stripped
  - hyphenated
  - underscored
  - lowercase variants
  - trimmed channel/version suffix variants where safe
- Deduplicate artifact paths and tag them with a source label for the UI.
- Preserve conservative filters around top-level folders and ambiguous matches.
- Add tests for:
  - receipt-backed matches
  - group containers
  - cookies / web storage
  - naming variants
  - helper tools and daemons

**Exit criteria**

- Explicit uninstall previews show a richer, source-labeled file plan without widening generic orphan scope.

### Phase 4: Uninstall Execution and Metadata Cleanup

**Primary files**

- `Broom/Services/AppUninstaller.swift`
- `Broom/ViewModels/UninstallerViewModel.swift`
- `Broom/Services/RunningAppDetector.swift`
- `BroomTests/AppUninstallerTests.swift`
- `BroomTests/UninstallerViewModelTests.swift`

**Likely new files**

- `Broom/Services/LaunchServicesManager.swift`
- `Broom/Services/LoginItemManager.swift`

**Tasks**

- Add explicit uninstall execution steps before and after file deletion:
  - unload matching launch agents / daemons
  - remove app-specific login items
  - unregister the app bundle from LaunchServices
  - rebuild or refresh LaunchServices after uninstall
- Keep `.app` bundle deletion last.
- Make metadata-cleanup failures non-fatal but visible in the final report.
- Extend uninstall progress reporting so the view model can surface:
  - metadata cleanup started
  - files removed
  - metadata refresh completed or skipped
- Add tests for:
  - app bundle deleted last
  - failed metadata cleanup does not abort uninstall
  - protected apps skip metadata cleanup

**Exit criteria**

- An uninstall removes the files and clears common metadata residue without introducing fragile failure modes.

### Phase 5: Sensitive Data and Final Delete Policy

**Primary files**

- `Broom/Utilities/SafeDelete.swift`
- `Broom/Services/FileCleaner.swift`
- `Broom/Services/AppUninstaller.swift`
- `Broom/Utilities/ExclusionList.swift`
- `Broom/Utilities/Constants.swift`
- `BroomTests/FileCleanerTests.swift`
- `BroomTests/AppUninstallerTests.swift`

**Likely new files**

- `Broom/Utilities/DeletePolicy.swift`
- `Broom/Utilities/ProtectedDataPolicy.swift`

**Tasks**

- Promote the provisional protected-data matcher introduced in Phase 2 into a dedicated policy type.
- Introduce a policy object in front of `trashItem` / `removeItem`.
- Validate deletion requests using:
  - absolute-path requirements
  - protected system prefixes
  - symlink rules
  - sensitive-data family rules
  - context mode: generic clean vs explicit uninstall
- Return structured delete results:
  - success
  - protected
  - missing
  - permission denied
  - unsafe symlink
  - system-protected
- Use stricter policy defaults for generic clean and orphan flows than for explicit uninstall.
- Add tests for:
  - protected roots
  - protected data families
  - symlink edge cases
  - uninstall-mode exceptions

**Exit criteria**

- Broom enforces safety at the final operation boundary rather than trusting only earlier filters.
- The temporary protected-data matcher used by orphan detection is replaced or absorbed by the shared policy implementation.

### Phase 6: UI, Preferences, and Messaging

**Primary files**

- `Broom/Views/Uninstaller/AppDetailView.swift`
- `Broom/Views/Uninstaller/UninstallConfirmView.swift`
- `Broom/Views/Uninstaller/UninstallerView.swift`
- `Broom/Views/Cleaner/ScanResultsView.swift`
- `Broom/Views/Components/ConfidenceBadge.swift`
- `Broom/Views/Settings/CleaningSettingsView.swift`
- `Broom/Utilities/AppPreferences.swift`
- `Broom/Utilities/ReleaseNotes.swift`

**Tasks**

- Group uninstall preview items by source instead of showing only a flat file list.
- Update orphan-results copy to explain the conservative policy.
- Decide whether orphan stale age remains hardcoded or becomes a visible preference.
- Ensure low-confidence leftover presentation remains visually secondary and unselected.
- Update release notes and docs so the reduced orphan list is framed as higher trust, not reduced capability.

**Exit criteria**

- The stricter policy is understandable from the UI without adding much complexity.

### Phase 7: Documentation and Verification

**Primary files**

- `docs/engineering/architecture.md`
- `docs/product/prd.md`
- `docs/releases/notes/`
- `README.md`

**Tasks**

- Update architecture docs for new services and delete-policy boundary.
- Update the PRD if orphan stale age or uninstall scope changes materially.
- Add release-note copy describing:
  - more complete uninstall cleanup
  - conservative leftover detection
  - stronger deletion guardrails
- Run and document verification:
  - unit tests
  - manual uninstall scenarios
  - manual orphan suppression scenarios

**Exit criteria**

- The implementation and the product story stay aligned.

---

## Suggested PR Split

1. `inventory-foundations`
   - inventory roots, installed snapshot, strict matcher split
2. `orphan-suppression`
   - suppression-first orphan rewrite, stale-age handling, protected-data policy
3. `uninstall-artifact-planner`
   - artifact providers, source tagging, receipt-based discovery
4. `uninstall-metadata-cleanup`
   - login items, LaunchServices cleanup, richer uninstall reporting
5. `delete-policy-hardening`
   - final delete validation and structured delete results
6. `ui-copy-and-docs`
   - uninstall grouping, orphan messaging, docs and release notes

This split keeps false-positive reduction ahead of uninstall expansion and makes review easier.

---

## Testing Plan

### Unit tests

- Installed-app discovery across standard and non-standard roots.
- Suppression-first orphan detection:
  - installed app present
  - running app present
  - recent modification
  - Spotlight hit
  - protected-data family
  - strict bundle-style matching
- Uninstall artifact providers:
  - receipts
  - login items
  - helpers
  - web storage
  - naming variants
- Delete-policy validation:
  - protected roots
  - unsafe symlinks
  - uninstall-mode exceptions

### Fixture / integration tests

- App with bundle in a non-standard install location should not surface orphan leftovers.
- Recently removed app should not surface generic leftovers until stale-age threshold is met.
- Explicit uninstall should plan and remove bundle + user data + related agents/helpers for a representative sample app fixture.
- Protected app data should never appear in generic orphan results.

### Manual QA

- Uninstall a common Electron app.
- Uninstall a Homebrew cask app.
- Uninstall a Setapp app.
- Verify no stale login item or LaunchServices residue remains.
- Verify orphan scan ignores fresh or active data after these flows.

---

## Risks

- Broader uninstall discovery can over-match if naming variants are not tightly scoped.
- Receipt parsing can surface too many files if trusted-path filtering is weak.
- Stricter orphan suppression will reduce the number of visible leftovers, which may look like "less cleaning" unless explained clearly.
- Additional checks can slow scans if not cached or bounded.

---

## Mitigations

- Use stricter matching for generic orphan mode than uninstall mode.
- Bound Spotlight and metadata queries with timeouts and local caching.
- Only trust receipt-discovered files under explicitly allowed prefixes.
- Add source annotations to uninstall artifacts so mismatches are easier to debug.
- Prefer suppressing an item over surfacing an uncertain one.

---

## Completion Checklist

- [ ] Installed app inventory includes standard and non-standard install sources.
- [ ] Orphan detection is suppression-first and stale-only by default.
- [ ] Generic orphan scan excludes protected-data families.
- [ ] Explicit uninstall includes receipts, login items, helpers, and metadata cleanup.
- [ ] Final delete validation exists and is tested.
- [ ] UI copy reflects conservative orphan behavior.
- [ ] Documentation and release notes are updated.
