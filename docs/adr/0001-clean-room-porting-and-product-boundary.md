# Clean-room porting from GPL sources, and the 1.4/1.5 product boundary

Broom adopts feature concepts from tw93/mole (GPL-3.0) while staying MIT-licensed: path catalogues, detection rules, recency thresholds, and safety behaviors are taken as facts, and every implementation is written independently in Swift. Mole shell or Go code is never translated, copied, or closely paraphrased. At the same time, Broom draws its product boundary to stay a disk-space reclamation and uninstall utility: project-artifact cleanup (Project Artifacts, §2.5) and installer-file sweep (Installers mode, §2.4.3) are adopted; live system monitoring (`mo status`), maintenance/optimize tasks (`mo optimize`), and a treemap disk visualizer are rejected because they conflict with the PRD non-goal against becoming an all-in-one system utility.

## Status

Accepted (2026-08), via the scope-lock effort charted in `.scratch/scope-lock-1-4/map.md`.

## Considered Options

- **Port Mole code directly** — rejected: would force Broom to GPL-3.0 and change the distribution story permanently.
- **Adopt owner-command cleanups** (shelling out to `pnpm store prune`, `nix-collect-garbage`, etc. like Mole's dev.sh does) — rejected for now: breaks Broom's zero-dependency, no-network character; revisit only with a deliberate architecture decision.
- **Adopt the full Mole surface** (dashboard, optimize, treemap analyzer) — rejected on product-boundary grounds above.

## Consequences

- Contributions porting Mole behaviors must cite the behavior/path list, not diff Mole source into Broom.
- Deferred Mole adoptions (Service Worker cache cleaning with a protected-domain list, sandboxed container caches, media app caches, editor `.obsolete` leftovers) need their own safety design before adoption; they are candidates for a future scope effort, not silent additions.
