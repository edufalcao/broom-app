# 06 - Write the scope lock: PRD revision + ADR

Type: task
Status: resolved
Blocked by: 05

## Question

Produce the destination deliverable, for human approval:

1. Revise `docs/product/prd.md` §2 (features) and §8 (roadmap) to reflect everything decided in tickets 02–05.
2. Write one ADR recording (a) the GPL clean-room porting stance toward tw93/mole and (b) the product-boundary decision (purge + installer sweep in; dashboard/optimize/treemap out).

The user reviews and approves; this ticket closes when the documents land.

## Answer

Documents landed:

1. **PRD revised** (`docs/product/prd.md`):
   - §2.1.1 scan-target table: five enrichment rows added, marked "Planned v1.4.0" (browser depth incl. Service Worker exclusion note, browser breadth, Apple system caches, filesystem-only dev-tool caches, Xcode Simulator data)
   - §2.4.3 Installers Mode (planned v1.5.0): types + ZIP payload rule, sources, 7-day age gate, Cleaner boundary
   - New §2.5 Feature F5: Project Artifacts (planned v1.5.0): families minus DerivedData, project discovery, recency classification
   - §8 roadmap rewritten: v1.4.0 fixes+enrichment table, v1.5.0 features table, later/unscheduled table, plus explicit product-boundary exclusions referencing the ADR
2. **ADR written**: `docs/adr/0001-clean-room-porting-and-product-boundary.md` — clean-room GPL stance and product-boundary decision with considered options and consequences
3. **In passing** (assigned by the map's fog notes): README Homebrew heading changed from "(coming soon)" to "(planned)"

Awaiting user review; changes are uncommitted working-tree edits for inspection.
