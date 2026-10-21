---
name: database-change
description: Workflow for proposing, writing, and executing Flyway migrations against PostgreSQL 16 schema.
---

# Database Change Workflow

Follow these rules whenever modifying the PostgreSQL schema.

## 1. Flyway Versioning
- Add migrations sequentially to `apps/api/src/main/resources/db/migration/`:
  - `V1__initial_schema.sql` (baseline)
  - `V2__<descriptive_snake_case_name>.sql`
- Never edit a migration file that has already run in production or shared environments.

## 2. PostgreSQL 16 & Concurrency Rules
- Use `TIMESTAMPTZ` for all timestamps with `DEFAULT CURRENT_TIMESTAMP`.
- Use `NUMERIC(12,2)` for all monetary fields.
- For exclusion constraints (e.g. bed date range exclusions), use `btree_gist` index types.
- Ensure foreign keys have proper indexes on child columns.
- Ensure all audit columns (`created_at`, `updated_at`) are present.

## 3. Verification
- Test migrations against local PostgreSQL 16 on OrbStack:
  ```bash
  docker exec -i devnagari-postgres psql -U devnagari -d devnagari_pg < apps/api/src/main/resources/db/migration/V<N>__<name>.sql
  ```
- Update `docs/architecture/domain-model.md` and `docs/PROJECT_SPEC.md` data dictionary.
