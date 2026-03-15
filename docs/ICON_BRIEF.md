# Broom — App Icon Brief

> Version: merged
> Date: 2026-03-15
> Purpose: single brief for icon exploration, selection, and final production handoff

---

## 1. Goal

Design an icon for **Broom**, a privacy-first macOS desktop utility that cleans junk files, app leftovers, and uninstalling targets safely.

The icon should feel:

- trustworthy
- lightweight
- clean
- native to macOS
- simple enough to read at small sizes

The icon should **not** feel:

- antivirus-like
- aggressive
- gimmicky
- overly cartoonish
- visually noisy

---

## 2. Product Meaning

Broom is a macOS desktop utility focused on:

- cleanup
- tidiness
- safety
- confidence
- mac-native polish

The icon does **not** need to communicate:

- speed
- “optimization”
- security scanning
- enterprise tooling

The app should read as a focused, honest utility, not a flashy “system booster.”

---

## 3. Core Constraints

- Prioritize strong readability at `16x16`, `32x32`, and `128x128`.
- Use a clear silhouette that remains recognizable without internal detail.
- Prefer one main symbol over a complex multi-object scene.
- Avoid tiny decorative elements that disappear at small sizes.
- Avoid photorealism, busy texturing, and heavy effects.
- The concept should still work if simplified for flatter macOS-style rendering.

---

## 4. Recommended Directions

Generate **3 distinct directions only**.

### Direction A: Minimal Broom Glyph

The simplest and safest route.

- Clean broom silhouette
- Strong geometric handle + bristle shape
- Minimal detail
- Premium/macOS feel rather than cartoon style

Why:

- strongest link to the app name
- easiest to recognize
- easiest to ship quickly

### Direction B: Sweep Arc + Debris Cue

Less literal, more refined.

- A sweeping arc or motion cue
- A small debris/spark cluster being cleared
- Broom implied or partially visible

Why:

- communicates cleaning action without feeling childish
- can look more elegant than a literal broom

### Direction C: Safety Badge + Broom

For a more trust-forward utility feel.

- Restrained badge, shield, or container form
- Broom integrated into the overall symbol
- Emphasis on safety and confidence

Why:

- reinforces “safe cleaner” positioning
- useful if a plain broom feels too generic

---

## 5. Style Guidance

Preferred style:

- modern macOS desktop icon
- clean vector shapes
- confident proportions
- limited palette
- subtle depth allowed, but not required

Avoid:

- neon gradients
- mascot/cartoon faces
- “magic cleaner” tropes
- toxic/radioactive imagery
- trash-can iconography as the primary symbol
- heavy sparkle overload
- emoji-like rendering

---

## 6. Color Direction

Use calm, credible colors.

Recommended palette families:

- deep teal + warm cream
- muted blue + soft silver
- forest green + pale stone
- slate + soft mint accent

Avoid:

- loud purple
- harsh red as primary
- overly saturated rainbow gradients

Do not lock the icon to green only. Green is acceptable, but the chosen palette should support trust and clarity more than “freshness” cliches.

---

## 7. macOS Production Guidance

### 7.1 Platform Fit

The final icon should feel at home beside native and high-quality third-party macOS apps.

- Use a square master composition sized for macOS app icon production.
- Favor a standard macOS-style icon composition rather than an irregular free-floating silhouette.
- Slight depth, soft shading, or gentle gradients are acceptable.
- Avoid heavy skeuomorphism or overly flat generic shapes.
- The icon should remain identifiable in the Dock and Finder without competing with system apps for attention.

### 7.2 Visual Construction

- Keep the primary object dominant.
- Aim for roughly `3-5` meaningful visual elements total.
- The icon should still read as a black silhouette if internal detail is removed.
- If a secondary accent exists, it must remain optional at small sizes.

### 7.3 Format Notes

- Start from a `1024x1024` square master.
- Prefer vector-first source where possible (`SVG`, design source, or clean layered export).
- Export final raster assets in `PNG`, `sRGB`.
- Do not rely on tiny texture, bristle strands, or micro-highlights for recognition.
- Validate the final result in Xcode’s asset catalog and on macOS before locking the design.

---

## 8. Prompt Template for Another LLM

Use this as the base prompt:

```text
Design a macOS app icon for "Broom", a privacy-first desktop utility that cleans junk files, app leftovers, and uninstalls apps safely.

The icon must feel trustworthy, lightweight, clean, and native to macOS. It should avoid looking like antivirus software, malware cleanup, or an aggressive "optimizer". Keep the silhouette simple and recognizable at small sizes like 16x16 and 32x32.

Generate 3 distinct concept directions:
1. Minimal broom glyph
2. Sweep arc plus subtle debris cleanup cue
3. Safety badge or shield integrated with a broom

Use clean vector-style forms, restrained detail, and a calm premium palette such as teal, muted blue, forest green, slate, cream, silver, or pale stone. Avoid cartoon mascots, trash can icons, neon gradients, radioactive motifs, and visual clutter.

For each concept, provide:
- a short concept name
- a one-paragraph rationale
- a visual description
- a recommended color palette
- notes about how it will read at small sizes

Bias toward macOS polish, clarity, and simplicity over novelty.
```

---

## 9. Expected Deliverables From the Other LLM

For concept generation, ask for:

- 3 icon concepts
- 1 rationale per concept
- 1 color palette per concept
- small-size readability notes
- a recommended winner

If it can produce assets, ask for:

- square icon composition
- vector-friendly output
- one preferred production candidate, not just loose explorations

---

## 10. Final Production Deliverables

Once a concept is selected, the production handoff should include:

- one `1024x1024` master asset
- source vector or editable source if available
- exported macOS app icon slices for `AppIcon.appiconset`

### Required macOS icon outputs

| Slot | Pixel Output | Notes |
|------|--------------|-------|
| `16x16 @1x` | `16x16` | Smallest app icon contexts |
| `16x16 @2x` | `32x32` | Retina small icon |
| `32x32 @1x` | `32x32` | Standard small icon |
| `32x32 @2x` | `64x64` | Retina |
| `128x128 @1x` | `128x128` | Standard app icon slot |
| `128x128 @2x` | `256x256` | Retina |
| `256x256 @1x` | `256x256` | Larger Finder/Dock contexts |
| `256x256 @2x` | `512x512` | Retina |
| `512x512 @1x` | `512x512` | Largest standard slot |
| `512x512 @2x` | `1024x1024` | Master Retina export |

---

## 11. Small-Size Legibility

The icon must be recognizable at `16x16` and `32x32`.

At these sizes:

- fine details should simplify or disappear cleanly
- the main silhouette alone should still identify the app
- accents should never be required for recognition
- internal contrast should remain strong enough to avoid muddy shapes

If needed, produce a slightly simplified small-size variant during refinement, but keep the core silhouette unchanged.

---

## 12. Evaluation Checklist

Use this checklist to choose a winner:

- Is the icon recognizable at a glance?
- Does it still read at `16x16`?
- Does it feel safe and trustworthy?
- Does it fit a macOS desktop utility?
- Is the broom metaphor distinctive enough without feeling generic?
- Is the visual language clean instead of noisy?
- Would this look credible in the Dock and Finder?

Reject concepts that:

- depend on tiny details
- look like antivirus software
- look childish
- overuse sparkles or gradients
- confuse “cleaning” with “deleting everything”

---

## 13. Recommendation

Start with **Direction A** as the default shipping path.

Use **Direction B** only if it stays very legible at small sizes.

Use **Direction C** only if it materially improves trust without collapsing into generic shield/badge utility art.

---

## 14. Next Step

Use this brief for the next concept generation round.

Have the other LLM place its concept output in `docs/`.

After that:

1. compare the concepts against this brief
2. choose one winner
3. refine that winner into final macOS app icon assets
