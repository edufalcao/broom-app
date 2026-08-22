# Wayfinder map: Scope lock for 1.4

Label: `wayfinder:map`

## Destination

A locked scope decision for Broom 1.4: `docs/product/prd.md` revised (features §2, roadmap §8) plus one ADR recording the GPL clean-room porting stance and the product-boundary decision, ending with a priority order that folds in 1.3.x release-plan Workstreams 2–5.

## Notes

- Domain: Broom, a free open-source macOS disk-cleanup and uninstaller utility. SwiftUI + Observation, MVVM with actor services, non-sandboxed, MIT licensed. See `docs/engineering/architecture.md` and `docs/product/prd.md`.
- Consult the `swiftui-expert-skill` skill when any UI design detail surfaces.
- Standing preference (decided at charting): **clean-room concept port** from tw93/mole. Mole is GPL-3.0; Broom stays MIT. Take behaviors, path knowledge, and safety model as facts; write all Swift independently. Never translate Mole shell/Go code.
- Standing preference: preserve Broom's suppression-first safety philosophy (10-gate orphan detection) when adopting any new cleanup category from Mole's catalogue.
- Decided at charting: candidate feature areas are project-artifact purge, installer-file sweep, and cleaner/uninstaller enrichment from Mole's path catalogue. System dashboard, optimize tasks, and treemap visualizer stay out (see below).
- Tracker: local markdown (`.scratch/`). No GitHub issues.

## Decisions so far

<!-- one line per closed ticket: [title](link): gist -->

- [Mole path catalogue vs Broom scan coverage](issues/01-mole-path-catalogue.md): full clean-room catalogue extracted; findings on branch `research/mole-path-catalogue` (`docs/research/mole-path-catalogue.md`). Broom lacks ~8 category families; purge has 35 artifact families with a 7-day recency rule; installer sweep is depth-2 across 10+ sources.
- [Purge feature direction](issues/02-purge-direction.md): adopt as fourth sidebar section "Project Artifacts"; Mole family list minus DerivedData (stays in Cleaner); 7-day fail-closed recency with default-deselect and delete-time re-check; fixed dev roots + CloudStorage plus user-editable root list in Settings.
- [Installer sweep direction](issues/03-installer-sweep-direction.md): adopt as an "Installers" mode inside Large Files; sources Downloads/Desktop/Documents + Homebrew DMG cache; Mole's file-type catalogue incl. ZIP payload check; uniform 7-day age gate (Settings-adjustable); Cleaner's Downloads row stays but never double-offers.
- [Cleaner enrichment set from Mole catalogue](issues/04-cleaner-enrichment.md): adopt browser depth (minus Service Worker) + breadth (10 more browsers), Apple system caches, filesystem-only dev-tool caches, Xcode Simulator extras, iCloud Drive Downloads as sweep source; reject owner-command cleanups; defer container/media/editor-leftover families to a future effort.
- [1.4 sequencing and release cut](issues/05-sequencing-and-release-cut.md): two cuts. 1.4.0 = false-positive fixes, blocked-results surfacing, TPC fix, Cleaner enrichment, UI-test target started early. 1.5.0 = Installers mode first, then Project Artifacts, with uninstall preview trust paired into 1.5.0 work.
- [Write the scope lock: PRD revision + ADR](issues/06-write-scope-lock.md): PRD §2.1.1 enriched, §2.4.3 Installers Mode and §2.5 Project Artifacts added, §8 roadmap rewritten to the 1.4.0/1.5.0 plan; `docs/adr/0001-clean-room-porting-and-product-boundary.md` records the clean-room stance and boundary; README Homebrew heading softened to "(planned)".
- 1.4.0 shipped (2026-08-22): false-positive fixes were already in 1.3.x (plan doc over-counted them); blocked-result surfacing, non-blocking LS refresh, UI-test target + coverage, and full Cleaner enrichment implemented, tested (185 unit + 3 UI), released as v1.4.0 with DMG asset.

## Not yet specified

<!-- empty: everything specifiable has been ticketed or ruled past the destination -->

## Out of scope

- Live system status dashboard (Mole `mo status`): breaks the PRD non-goal against all-in-one system utilities.
- Maintenance/optimize tasks (Mole `mo optimize`: DNS flush, Spotlight verify, SQLite vacuum): same non-goal conflict.
- Treemap/disk-usage visualizer (Mole `mo analyze`): overlaps the existing Large Files finder; revisit only if that finder proves insufficient.
- Duplicate file finder, scheduled cleaning, Sparkle auto-update, CLI, localization: already on the PRD roadmap independently; not part of this scope lock.
- Deferred Mole adoptions (Service Worker caches, sandboxed container caches, owner-command dev-tool cleanups, media app caches, editor `.obsolete` leftovers): ruled past this effort's destination by [Cleaner enrichment set from Mole catalogue](issues/04-cleaner-enrichment.md); candidates for a future scope effort.
- Vendor-family suppression policy for shared frameworks: sharp question, but it belongs to the 1.4.0 fix implementation effort, not the scope lock; sequenced there by [1.4 sequencing and release cut](issues/05-sequencing-and-release-cut.md).
- UI-test target design (accessibilityIdentifier rollout plan, CI coverage flag): belongs to 1.4.0 execution; only its sequencing was this map's business.
- README "Homebrew install coming soon" claim: a roadmap-wording detail for the PRD §8 revision in [Write the scope lock](issues/06-write-scope-lock.md) to settle in passing, not a decision worth its own ticket.
