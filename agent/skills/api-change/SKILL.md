---
name: api-change
description: Workflow for proposing, modifying, and updating API endpoints while keeping contracts/openapi.yaml, Spring Boot controllers, and React clients in sync.
---

# API Change Workflow

Use this workflow whenever adding, modifying, or deprecating REST API endpoints in Devnagari PG & Hostel.

## 1. Contract-First Integrity
1. Check `contracts/openapi.yaml`.
2. Propose or update endpoint paths under `/api/v1/...`.
3. Ensure request/response schemas use exact data types:
   - Money: `string` (formatted decimal e.g. `"1500.00"`) or number with 2 decimal precision.
   - IDs: `UUID` format.
   - Dates: ISO-8601 (`YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ssZ`).

## 2. Server Implementation (`apps/api`)
1. Implement or modify the `@RestController` in the corresponding domain package under `com.devnagari.pg.<domain>`.
2. Enforce server-side authorization:
   - Verify staff role/permissions.
   - Scrape and check branch boundary (`branch_id`).
3. Return standard error envelopes for validation and business rule violations.

## 3. Client Alignment (`apps/web`)
1. Update API client methods in `apps/web/src/api/` or TanStack Query hooks.
2. Verify TypeScript types match the contract.

## 4. Documentation & Tests
1. Run `./gradlew test` in `apps/api`.
2. Document the change in `docs/PROJECT_SPEC.md` if an API capability was added or modified.
