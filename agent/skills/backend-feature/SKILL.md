---
name: backend-feature
description: Guide for developing backend vertical features in Spring Boot 3 modular monolith adhering to Ponytail minimal-code rules and transactional guardrails.
---

# Backend Feature Workflow

Use this workflow to build or extend server-side business features in `apps/api`.

## 1. Domain Organization
- Place code in `com.devnagari.pg.<domain>` (e.g. `identity`, `accommodation`, `onboarding`, `billing`, `maintenance`, `cleaning`).
- Structure per domain:
  - `controller/` — REST controllers & DTO records.
  - `service/` — Business logic and transaction orchestration.
  - `repository/` — Spring Data JPA repositories.
  - `entity/` — JPA entities mapped to PostgreSQL 16 schema.

## 2. Inviolable Backend Rules
- **Bed Locking:** Use `@Lock(LockModeType.PESSIMISTIC_WRITE)` when reserving or allocating beds.
- **Financial Precision:** Always use `BigDecimal` for currency. Never use `float` or `double`.
- **Branch Scoping:** Every query retrieving branch-level assets (rooms, beds, charges, complaints) must enforce `WHERE branch_id IN (:userBranches)`.
- **Ponytail Simplicity:** Avoid redundant interface declarations where there is only one implementation. Use Java 21 records for DTOs.

## 3. Verification
- Add integration test in `src/test/java/com/devnagari/pg/` using `@SpringBootTest` or `@DataJpaTest`.
- Run `./gradlew test`.
