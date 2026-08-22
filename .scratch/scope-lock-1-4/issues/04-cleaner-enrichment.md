# 04 - Cleaner enrichment set from Mole catalogue

Type: grilling
Status: resolved
Blocked by: 01

## Question

Using the diff from ticket 01, decide which Mole catalogue paths/categories Broom adopts into its existing Cleaner and Uninstaller, subject to Broom's suppression-first gates (10-gate orphan detection, protected-data families, exclusion list). Which additions are worth the safety-review cost, and which are rejected even though Mole cleans them? Output is a concrete adopt/reject list for PRD §2.

## Answer

Adopt/reject list locked (all seven decisions accepted as recommended). **Adopt into 1.4:**

1. **Browser depth**: per-profile GPUCache, ShaderCache/Dawn caches, CRX component caches. Service Worker caches **deferred** (needs its own protected-domain safety design).
2. **Browser breadth**: Vivaldi, Opera, Zen, Comet, Helium, Orion, QQ, Yandex, Dia, Thunderbird join the existing six browsers.
3. **Apple system caches**: QuickLook thumbnails, helpd, parsecd, GeoServices, Saved Application State, Suggestions, Messages sticker caches → System Caches phase. Sandboxed container caches (App Store, Word/Excel, UTM) **deferred**.
4. **Dev-tool caches (filesystem-only)**: Cargo registry/cache, gem/bundler, bun, Corepack, Docker BuildX, rbenv downloads → Developer Caches phase. Owner-command cleanups (`pnpm store prune`, `uv prune`, `go clean`, `nix-collect-garbage`) **rejected for now** — shelling out to third-party binaries breaks the zero-dependency, no-network character; revisit only with a deliberate architecture decision.
5. **Xcode Simulator extras**: Simulator Caches, device tmp, CoreSimulator logs, gated on Xcode/Simulator not running.
6. **Installer sweep leftovers**: iCloud Drive Downloads adopted as a sweep source. Telegram Desktop folders and `/Users/Shared` stay out permanently.

**Deferred to a future effort** (not 1.4): Service Worker caches, sandboxed container caches, media app caches (FCP/DaVinci/JianyingPro), editor `.obsolete` extension leftovers.

All adoptions pass through ExclusionList + user safe-list and the existing suppression gates; running-app checks apply wherever a tool may be live.

Clean-room note: path knowledge adopted as facts from ticket 01's research; implementation written independently in Swift.
