# 03 - Installer sweep direction

Type: grilling
Status: resolved
Blocked by: 01

## Question

Should Broom adopt an installer-file sweep (Mole `mo installer` concept), and if so, what is its locked direction: file types (DMG/PKG/ISO/XIP/ZIP), whether sources beyond Downloads are in scope (Homebrew caches, Mail attachments, iCloud), and how it relates to the existing Downloads-awareness row in the Cleaner. Direction only; UX design details are fog for a later effort.

## Answer

Adopt. Locked direction (all six decisions accepted as recommended):

1. **Adopt** the installer-file sweep as a new capability.
2. **Placement**: an "Installers" mode inside the existing **Large Files** sidebar section — same machinery (home-dir walk, size/date sort, Finder reveal, trash-only delete). No fifth sidebar tab.
3. **Sources**: Downloads, Desktop, Documents, plus Homebrew's DMG cache. Mail Downloads stays with Cleaner's Mail Attachments phase (no double-offering); iCloud Drive, Telegram Desktop, and /Users/Shared deferred to ticket 04's enrichment decision.
4. **File types**: Mole's catalogue adopted as facts — `.dmg`, `.pkg`, `.mpkg`, `.iso`, `.xip` by extension; `.zip` only if its first ~50 entries contain installer-looking payload (.app/.pkg/.dmg/.xip).
5. **Age gate**: one uniform threshold, default 7 days, adjustable in Settings; mounted/in-use detection applies regardless of age.
6. **Cleaner boundary**: Cleaner's Downloads row stays as generic awareness but never lists files the sweep already surfaces; no file offered twice.

Clean-room note: behaviors adopted as facts from ticket 01's research; implementation written independently in Swift.
