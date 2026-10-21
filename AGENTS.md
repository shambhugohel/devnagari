# Devnagari PG & Hostel — AI Engineering Standard (AGENTS.md)

This repository follows a strict agent-independent engineering standard. Any coding assistant (Claude Code, Antigravity, Cursor, Copilot) must follow these operational rules.

---

## 1. Single Source of Truth

* All system architecture, domain models, confirmed requirements, and pending questions are recorded in [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md).
* Manually maintained documentation and generated documentation must never compete:
  * Manually maintained: `docs/product/*`, `docs/architecture/*`, `contracts/openapi.yaml`.
  * Generated: `docs/generated/*`, API client SDKs.
* If source files change, re-analyze only the affected slice. Do not rewrite verified requirements with inferred data.
* **Requirements-Status Convention:** Every requirement must be tagged as:
  * `[CONFIRMED]`: Approved business logic or inspected reference behavior.
  * `[PROPOSED]`: Recommended engineering approach awaiting sign-off.
  * `[OPEN QUESTION]`: Unresolved business decision requiring stakeholder confirmation.

---

## 2. Context-Loading Protocol for Agents

Before implementing or modifying code, agents must:
1. Read [docs/index.md](docs/index.md) to locate the relevant bounded domain.
2. Load only the specific section of [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md), [contracts/openapi.yaml](contracts/openapi.yaml), or [docs/architecture/domain-model.md](docs/architecture/domain-model.md) relevant to the feature.
3. Check [agent/policies/coding-standards.md](agent/policies/coding-standards.md) for Ponytail minimal-code constraints.
4. Execute the appropriate skill under `agent/skills/`.

---

## 3. Directory Layout & Module Ownership

```
devnagari-pg/
├── AGENTS.md                  # Root AI operating instructions (this file)
├── CLAUDE.md                  # Thin compatibility adapter for Claude Code
├── apps/
│   ├── web/                   # React + TypeScript + Vite frontend
│   └── api/                   # Java + Spring Boot modular monolith
├── contracts/
│   └── openapi.yaml           # Canonical API contract
├── docs/
│   ├── PROJECT_SPEC.md        # Comprehensive master specification
│   ├── product/               # Requirements, user roles, business rules
│   └── architecture/          # ADRs, domain model, security, finance
├── agent/
│   ├── skills/                # Reusable engineering workflows
│   ├── workflows/             # Task-specific recipes (feature, bug-fix)
│   └── policies/              # Security, database, and documentation rules
└── scripts/                   # Verification and build scripts
```

---

## 4. Strict Development Rules

### Rule 1: Concurrency-Safe Bed Operations (Mutex Lock on Bed Row)
* The target `beds` row is the authoritative concurrency mutex for all room/bed state changes.
* Every check-in, reservation, cancellation, and room transfer must acquire a transactional lock (`PESSIMISTIC_WRITE`: `SELECT ... FROM beds WHERE id = :bedId FOR UPDATE`) on the target bed before validating availability.
* While holding the lock, the service must validate that:
  1. No active allocation exists in `bed_allocations` for the target stay window (backed by PostgreSQL `btree_gist` range exclusion constraint `no_overlapping_bed_stays`).
  2. No active unexpired reservation exists in `bed_reservations` for the overlapping move-in date.
* Two residents or reservations can never have overlapping active claims on the same bed.

### Rule 2: Occupancy History Preservation
* Room transfers and departures close allocations with timestamps and audit reasons. They never update or delete historical occupancy records.

### Rule 3: Financial Reconciliation
* Monetary values must use `BigDecimal` in Java and `NUMERIC(12,2)` in PostgreSQL. Never use floating-point types (`float`, `double`).
* Invoices (`charges`), receipts (`payments`), and allocations (`payment_allocations`) must strictly reconcile to the paisa.
* Security deposits are balance-sheet liabilities, not rental income.

### Rule 4: Server-Enforced Branch Authorization
* Client-side UI filtering is for user experience only.
* Spring Security policies and service queries must strictly enforce branch authorization boundaries (`WHERE branch_id IN (:userBranchIds)`).

### Rule 5: UIDAI Aadhaar Compliance
* Raw 12-digit Aadhaar numbers must never be stored in the database.
* Store only masked strings (`XXXX-XXXX-1234`) and object-storage UUID pointers for scanned KYC documents.

### Rule 6: Ponytail Minimal Coding Discipline
* Follow [agent/policies/coding-standards.md](agent/policies/coding-standards.md): Prefer existing code, native platform features, and minimal solutions over premature abstractions (YAGNI).
* Never introduce speculative frameworks, redundant layers, or unneeded dependencies.
* Never sacrifice concurrency safety, financial precision, or tests for line-count reduction.

---

## 5. Standard Skill Execution
When instructed to build or modify features, load and execute [agent/skills/implement-feature/SKILL.md](agent/skills/implement-feature/SKILL.md).
