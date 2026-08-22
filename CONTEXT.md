# Broom

A free, open-source macOS utility for reclaiming disk space and cleanly uninstalling apps. Privacy-respecting: no telemetry, no network access.

## Language

### Cleaning

**Cleaner**:
The sidebar section that scans and cleans shared cache stores: system caches, browser caches, logs, developer-tool caches. Organized as a flat category checklist.
_Avoid_: Purge (reserved for the Project Artifacts feature)

**Project Artifacts**:
Regenerable build outputs found inside project directories (e.g. `node_modules`, `target`, `.build`), offered per-project in their own sidebar section.
_Avoid_: Dev caches (that means shared stores in the Cleaner), purge targets

**Shared cache store**:
A cache owned by a tool or app outside any project tree (npm cache, Homebrew cache, DerivedData). Belongs to the Cleaner, never to Project Artifacts.

**Recency classification**:
Labeling a candidate item as recent, old, or uncertain by modification time against a threshold; uncertain is treated as protected.
_Avoid_: Staleness (Broom's stale-age gate on orphans is a different mechanism)

**Installer**:
A leftover installation file (.dmg, .pkg, .mpkg, .iso, .xip) or an archive proven to contain one. Surfaced individually in the Installers mode of the Large Files section.
_Avoid_: DMG (too narrow), setup file

### Safety

**Suppression-first detection**:
An orphan candidate is only offered after passing every suppression gate; anything uncertain stays hidden or deselected by default.
_Avoid_: Confidence-first cleanup

**Safe list**:
User-maintained list of paths Broom must never offer for deletion.
