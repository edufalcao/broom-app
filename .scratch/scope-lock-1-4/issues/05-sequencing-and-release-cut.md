# 05 - 1.4 sequencing and release cut

Type: grilling
Status: resolved
Blocked by: 02, 03, 04

## Question

Given the locked feature directions from tickets 02–04, set the priority order for 1.4: how do 1.3.x release-plan Workstreams 2–5 (uninstall preview trust, blocked-result surfacing, UI test target, LaunchServices TPC fix) rank against purge, installer sweep, and cleaner enrichment? Decide what ships in the first 1.4 cut versus later. Output feeds directly into PRD §8 roadmap revision.

## Answer

Staged plan locked (all five decisions accepted as recommended):

**1.4.0 — fixes + enrichment** ("clean what's already covered, correctly"):
1. Known false-positive orphan fixes from the 1.3.0 plan (Teams migration containers, `group.com.apple.*`, Microsoft AutoUpdate helpers) — wrong suggestions hurt users today
2. Blocked-result surfacing: completion screens finally read `itemsBlocked` and show what was blocked and why
3. LaunchServices `DispatchGroup.wait` → non-blocking pattern (TPC fix)
4. Cleaner enrichment per [Cleaner enrichment set from Mole catalogue](04-cleaner-enrichment.md)
5. UI-test target + first `accessibilityIdentifier`s land at the **start** of this work; every subsequent change adds its own identifiers

**1.5.0 — features**:
1. Installers mode inside Large Files (cheaper; extends existing machinery) per [Installer sweep direction](03-installer-sweep-direction.md)
2. Project Artifacts sidebar section (new scanner service + Settings surface) per [Purge feature direction](02-purge-direction.md)
3. Uninstall preview trust (Workstream 2: single editable backing plan, mixed-state toggles, duplicate "ago" label) paired early with this feature work

Version numbering: 1.4.0 / 1.5.0 minor bumps as named. Output feeds the PRD §8 revision in [Write the scope lock](06-write-scope-lock.md).
