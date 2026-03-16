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
  Published release notes for shipped versions only.
- [Release Plans](./releases/plans/)
  Planning documents for upcoming, in-progress, or recently implemented releases.
  - [1.3.0 Plan](./releases/plans/1.3.0.md)
    Product parity and trust pass implemented on `main`.

## Placement Rules

- Keep the `docs/` root limited to this index plus category folders.
- Put evergreen product and engineering references in their domain folders.
- Put shipped release notes in `docs/releases/notes/`.
- Put release-planning docs in `docs/releases/plans/` and update their status when implementation lands.
- Do not mix planning documents with published release notes.
