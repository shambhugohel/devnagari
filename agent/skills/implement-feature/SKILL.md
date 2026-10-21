# Implement Feature

Use this skill when developing any new user story, API endpoint, screen, or domain workflow.

---

## 1. Understand
- Read [docs/PROJECT_SPEC.md](file:///Users/dev/P_PROJECT/DEVNAGRI/docs/PROJECT_SPEC.md).
- Find the relevant approved requirements and business rules in `docs/product/`.
- Inspect existing implementations and tests in `apps/web/` and `apps/api/`.
- Identify relevant Architecture Decision Records (ADRs) in `docs/architecture/decisions/`.
- Record ambiguities; do not invent requirements or database columns.

## 2. Plan
- Identify affected frontend features (`apps/web/src/features/*`) and backend packages (`apps/api/src/main/java/com/devnagari/pg/*`).
- Identify data model changes and Flyway database migrations needed (`V...__name.sql`).
- Identify API contract modifications in `contracts/openapi.yaml`.
- Identify authorization rules and branch-scope implications.
- Identify unit, integration, and UI tests required.
- Favor the smallest viable change that cleanly fulfills the requirement.

## 3. Implement
- Follow established module and package boundaries.
- **Apply Ponytail Decision Hierarchy:**
  1. *Does this need to exist?* (YAGNI).
  2. *Can existing project code solve it?* (Reuse `apps/web/src/components/ui/` or `apps/api/src/.../shared/`).
  3. *Can the platform solve it natively?* (Native HTML5 inputs, modern Java standard library APIs).
  4. *Is an existing dependency sufficient?* (Avoid introducing new libraries for single helpers).
  5. *Write the minimum necessary code.*
- Reuse established UI tokens and design components in `apps/web/src/components/ui/`.
- Keep business logic in backend application and domain services, not in UI components or SQL triggers.
- Use explicit database transactions (`@Transactional`) and locking for multi-entity operations requiring atomic consistency.
- Never sacrifice concurrency safety (`PESSIMISTIC_WRITE`, range exclusion constraints), financial precision (`BigDecimal`/`NUMERIC(12,2)`), or branch authorization to reduce line counts.
- Do not add external dependencies without explicit architectural justification.

## 4. Verify
- Run unit and integration tests (`./gradlew test` and `npm test`).
- Verify database migration scripts with Flyway.
- Verify branch isolation and role permission enforcement.
- Ensure strict monetary calculations (`BigDecimal` / `NUMERIC(12,2)`).

## 5. Synchronize Documentation
- Update approved requirements in `docs/product/requirements.md` if business rules evolve.
- Update architecture documents when an ADR or schema decision is revised.
- Update `contracts/openapi.yaml` when an API signature changes.
- Never manually edit generated documentation files.

## 6. Report
Deliver a structured completion summary:
- What was changed and the rationale.
- Files and modules modified.
- Tests executed and outcomes.
- Documentation and contracts synchronized.
- Any remaining assumptions or unresolved questions.
