# Docs

Project documentation is grouped by domain and by release-document lifecycle.

## Structure

### Product
- [PRD](./product/prd.md)
  Product requirements, scope, and shipped feature expectations.

### Engineering
- [Architecture](./engineering/architecture.md)
  Technical architecture, layering, and codebase structure.
- [Implementation Plan](./engineering/implementation-plan.md)
  Implementation history, execution steps, and current milestone status.

### Design
- [Icon Brief](./design/icon-brief.md)
  App icon exploration and handoff guidance.

### Releases
- [Release Notes](./releases/notes/)
  Published release notes for shipped versions only. The current baseline release note is `1.0.0`.
- [Release Plans](./releases/plans/)
  Reserved for future release planning documents when the next version is scoped.

## Placement Rules

- Keep the `docs/` root limited to this index plus category folders.
- Put evergreen product and engineering references in their domain folders.
- Put shipped release notes in `docs/releases/notes/`.
- Put future release-planning docs in `docs/releases/plans/` when a new version is actively being scoped.
- Do not mix planning documents with published release notes.
