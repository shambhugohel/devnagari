---
name: update-docs
description: Workflow for updating documentation and keeping docs/PROJECT_SPEC.md synchronized with codebase realities.
---

# Documentation Sync Workflow

Maintain documentation integrity across all project repositories and docs.

## 1. Source of Truth Maintenance
- [docs/PROJECT_SPEC.md](file:///Users/dev/P_PROJECT/DEVNAGRI/docs/PROJECT_SPEC.md) is the master specification.
- If a business rule, status lifecycle, or entity model changes:
  1. Update the corresponding section in `docs/PROJECT_SPEC.md`.
  2. Increment specification version in header if substantive.
  3. Update `docs/architecture/domain-model.md` if schema tables/columns changed.

## 2. API Contract Sync
- If an endpoint or schema changes, update `contracts/openapi.yaml`.
- Do not let code and OpenAPI drift.

## 3. Architecture Decision Records (ADRs)
- If a fundamental technology, design pattern, or structural boundary is decided or altered, append an ADR under `docs/architecture/decisions/`.
