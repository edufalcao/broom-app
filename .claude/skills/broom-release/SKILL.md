---
name: broom-release
description: Prepare, publish, and verify releases for the Broom app repository. Use when asked to bump a Broom version, write or update Broom release notes, create a Broom git tag, publish a Broom release, rerun the Broom release workflow, or fix the body/title/assets of a workflow-generated GitHub release.
---

# Broom Release

Prepare Broom releases in the repository root. Treat the GitHub Actions `Release` workflow as the source of truth for the GitHub release object and DMG asset.

## Workflow

1. Inspect release state before changing anything.
   - Check `git status --short`.
   - Check `.github/workflows/release.yml`.
   - Check the latest release body when formatting is ambiguous:
     - `gh release view v1.0.0 --json body`

2. Prepare release metadata first.
   - Update `project.yml` version fields when the version changes.
   - Update `CHANGELOG.md`.
   - Create or update `docs/releases/notes/X.Y.Z.md`.
   - If the release needs planning notes, keep them in `docs/releases/plans/X.Y.Z.md`.
   - If the app shows release notes in-product, update that content too.

3. Write release notes using the Broom format.
   - Read `references/release-format.md`.
   - Match the markdown structure used by `v1.0.0`.
   - Keep the title, intro paragraph, horizontal rule, `###` sections, and install block style consistent.

4. Verify before publishing when code changed.
   - Run `xcodegen generate`.
   - Run `xcodebuild -project Broom.xcodeproj -scheme Broom -configuration Debug build`.
   - Run `xcodebuild -project Broom.xcodeproj -scheme Broom -configuration Debug test`.

5. Publish in this order.
   - Commit the release changes.
   - Create an annotated tag: `git tag -a vX.Y.Z -m "Broom X.Y.Z"`.
   - Push `main`.
   - Push the tag.

6. Do not manually create the GitHub release.
   - Pushing the tag triggers `.github/workflows/release.yml`.
   - Wait for the workflow to finish and create the DMG plus release object.
   - Use `gh run list` or `gh run watch <run-id>` to monitor it.

7. After the workflow-created release exists, apply the curated notes.
   - Run:
     - `gh release edit vX.Y.Z --title "Broom X.Y.Z" --notes-file docs/releases/notes/X.Y.Z.md`
   - Verify:
     - `gh release view vX.Y.Z --json name,body,url,assets`
   - Confirm the DMG asset name matches `Broom-vX.Y.Z.dmg`.

## Recovery

If someone manually created the release before the workflow:

1. Delete the manual release:
   - `gh release delete vX.Y.Z --yes`
2. Rerun the tag-triggered `Release` workflow.
3. Wait for it to recreate the release and asset.
4. Reapply the curated title and notes with `gh release edit`.

## Finish

- Report the release URL.
- Report the workflow run URL when relevant.
- Confirm whether the working tree is clean.
