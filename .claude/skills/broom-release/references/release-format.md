# Broom Release Notes Format

Use the markdown structure from `v1.0.0` as the baseline.

## Required shape

```md
## Broom vX.Y.Z - Subtitle

**Broom X.Y.Z** short introductory paragraph summarizing the release.

---

### System Cleaner
- ...

### App Leftover Cleanup
- ...

### App Uninstaller
- ...

### Settings
- ...

### Safety
- ...

### Quality
- ...

### Install
Download **Broom-vX.Y.Z.dmg** below, open it, and drag Broom to your Applications folder.
```

## Rules

- Keep the top heading at `##`.
- Keep the intro as one bold lead-in sentence or paragraph.
- Insert a horizontal rule `---` before the section list.
- Use `###` headings for sections.
- Use flat bullet lists under each section.
- Keep section names close to the `v1.0.0` style unless the release clearly needs a different label.
- Include only sections that have real content, but preserve the same overall tone and hierarchy.
- End with the `### Install` block.

## When in doubt

Inspect the canonical example directly:

```bash
gh release view v1.0.0 --json body
```
