# 01 - Mole path catalogue vs Broom scan coverage

Type: research
Status: resolved
Blocked by:

## Question

Extract tw93/mole's cleanup knowledge as facts (clean-room: behaviors and path lists only, no code translation):

1. The full catalogue of safe-to-delete cache/log/leftover paths in `lib/clean/*.sh`, with any safety rules attached (age thresholds, running-app checks, whitelist behavior).
2. The project-artifact families in `mo purge` (`node_modules`, `target`, `.build`, `dist`, DerivedData, etc.), their detection rules, and the recency-aware default-deselection logic.
3. The installer-file sweep sources in `mo installer` (file types, Downloads/Homebrew/Mail/iCloud/Telegram locations).
4. Diff all three against Broom's current scan coverage (`Broom/Services/FileScanner.swift`, `LargeFileScanner.swift`) and report what Broom already covers, what it lacks, and where Mole's paths would need Broom's suppression gates applied.

## Answer

Full findings committed on branch `research/mole-path-catalogue` (commit `dbf79fd`), file `docs/research/mole-path-catalogue.md`. Summary:

**Broom already covers**: generic `~/Library/Caches`, logs + DiagnosticReports, age-gated temps, browser HTTP caches (Chrome/Firefox/Safari/Arc/Brave/Edge), Xcode DerivedData/Archives, SPM/CocoaPods/Homebrew/npm/Yarn/pip caches, Docker data, old Homebrew kegs, Mail attachments, Downloads awareness-only, home-wide .DS_Store, 10-gate orphan detection.

**Missing categories** (candidates for ticket 04): deeper per-profile browser caches (GPUCache, ShaderCache, Service Worker) plus ~10 more browsers; Apple system caches (QuickLook, helpd, parsecd, GeoServices, Saved Application State); dev-tool caches (pnpm/bun/uv/Go/Cargo/gem/kube/Nix/BuildX); in-project build caches (`__pycache__`, `.next/cache`, `.dart_tool`) scoped to project-indicator roots; Xcode Simulator extras; media generated caches (FCP, DaVinci — running-app gate mandatory); obsolete VS Code/Cursor extensions via `.obsolete`.

**Purge families** (ticket 02): 35 names incl. node_modules, target, build, dist, venv, .next, .gradle, DerivedData, Pods. Detection: known dev roots + CloudStorage, depth 1–6, project indicators (.git, package.json, Cargo.toml…), CACHEDIR.TAG honoured. Recency: 7-day recursive mtime probe, fail-closed to uncertain, recent categories default-deselected.

**Installer sweep** (ticket 03): depth-2 scan of ~/Downloads, ~/Desktop, ~/Documents, ~/Public, ~/Library/Downloads, /Users/Shared, Homebrew cache, iCloud Drive Downloads, Mail container, Telegram Desktop. Types: .dmg/.pkg/.mpkg/.iso/.xip/.zip (zip qualifies only if first 50 entries contain .app/.pkg/.dmg/.xip). Plus macOS installers in /Applications if >14 days old and not current OS.

**Gate mapping**: every adoption passes ExclusionList + user safe-list; dev-tool targets need fail-closed running-process checks; recency facts to reuse: purge 7d, mail 30d, macOS installers 14d, brew prune=30 with 50MB floor, Nix 30d, GPU caches 1d; App Support/container targets reuse strict bundle-ID match so live apps' state is never offered.
