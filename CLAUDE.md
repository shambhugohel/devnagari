# CLAUDE.md — Devnagari PG & Hostel

This document provides essential instructions for Claude Code and other AI coding agents working in this repository.

---

## 1. Golden Rules & Source of Truth
1. **The repository is the source of truth.** Always read [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md) and [docs/index.md](docs/index.md) before implementing or modifying features.
2. **Never invent business rules or schema columns.** If a requirement is ambiguous or missing, mark it as `[OPEN QUESTION]` and verify against the specifications.
3. **Respect module boundaries.** Do not leak internal module implementation details across package boundaries.
4. **Synchronize documentation.** When confirmed requirements or architecture decisions change, update [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md) and the corresponding ADR in `docs/architecture/decisions/`. Never manually edit generated documentation.

---

## 2. Technology Stack & Key Conventions
* **Frontend (`apps/web`):**
  * React, TypeScript, Vite.
  * Server State: TanStack Query.
  * Styling: Consistent CSS tokens, clean components, responsive layout.
  * Structure: Feature-folder organization (`src/features/<domain>/`).
* **Backend (`apps/api`):**
  * Java LTS (Java 21) + Spring Boot 3.x.
  * Build: Gradle Kotlin DSL (`build.gradle.kts`), run via `./gradlew`.
  * Architecture: Modular monolith organized by business capability (`com.devnagari.pg.<domain>`), not global technical layers.
  * Persistence: PostgreSQL 16+ with Flyway migrations in `src/main/resources/db/migration`.
  * Security: Spring Security with stateless JWT. Branch-level scoping enforced on the server for all data queries.
* **API Contracts (`contracts/`):**
  * Canonical contract: `contracts/openapi.yaml`. Update the contract before changing client/server signatures.

---

## 3. High-Priority Architectural Constraints
1. **Atomic Bed Mutex:** Lock the target `beds` row (`PESSIMISTIC_WRITE`) for check-ins, reservations, transfers, and cancellations. Enforce range exclusion constraints (`btree_gist`) in PostgreSQL.
2. **Preserve Resident History:** Room transfers and checkouts close allocation records with end dates; they never overwrite historical occupancy records.
3. **Financial Precision:** Currency values must strictly use `BigDecimal` in Java and `NUMERIC(12,2)` in PostgreSQL. Never use floating-point types (`float`, `double`).
4. **Server-Enforced Branch Authorization:** Every query must enforce `WHERE branch_id IN (:userBranchIds)` unless the user is an unrestricted `ADMIN_OWNER`.
5. **UIDAI Aadhaar Compliance:** Store only masked numbers (`XXXX-XXXX-1234`) and object-storage UUID pointers.

---

## 4. Feature Implementation Lifecycle
For any new feature or refactor, follow the 6-step lifecycle defined in [agent/skills/implement-feature/SKILL.md](agent/skills/implement-feature/SKILL.md):
1. **Understand:** Read `docs/PROJECT_SPEC.md` and related ADRs.
2. **Plan:** Identify affected modules, contracts, and migrations.
3. **Implement:** Follow module boundaries and transactional consistency.
4. **Verify:** Run unit, integration, and architecture checks.
5. **Synchronize:** Update specs, ADRs, and OpenAPI contracts.
6. **Report:** Return clear changelog, affected files, tests run, and remaining questions.
