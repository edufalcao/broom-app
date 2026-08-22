# 02 - Purge feature direction

Type: grilling
Status: resolved
Blocked by: 01

## Question

Should Broom adopt a project-artifact purge feature (Mole `mo purge` concept), and if so, what is its locked direction: which artifact families are in, how recency-aware defaults should behave philosophically (deselect recent projects by default?), and whether it is a new sidebar section or an extension of the existing Cleaner's developer-cache category? Direction only; design details are fog for a later effort.

## Answer

Adopt. Locked direction (all five decisions accepted as recommended):

1. **Adopt** project-artifact purge as a new capability: reclaim regenerable build artifacts found inside project directories (`node_modules`, `target`, `.build`, …). Distinct from Cleaner, which handles shared cache stores only.
2. **Family set**: the Mole 35-family list minus `DerivedData` (already offered by Cleaner's Xcode Data phase; shared stores never appear in purge). In-project families like `Pods` and `.build` stay in purge.
3. **Placement**: a fourth sidebar section named **Project Artifacts**, not a Cleaner category — project-centric interaction model (grouped by project, recency-labeled rows) vs Cleaner's flat category checklist.
4. **Recency behavior**: adopt Mole's scheme wholesale — 7-day threshold, recursive mtime probe, fail closed to "uncertain" (= protected), recent artifacts deselected by default with an age label, re-check just before deletion that drops anything that went active. Maps to Broom's confidence-badge pattern (recent = low confidence = deselected).
5. **Search roots**: fixed dev roots + CloudStorage as defaults, plus a user-editable root list in Settings (same pattern as ExclusionList/safe-list).

Clean-room note: all behaviors adopted as facts from ticket 01's research; implementation written independently in Swift.
