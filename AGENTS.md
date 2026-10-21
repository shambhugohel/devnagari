# Devnagari PG & Hostel — AI Engineering Standard (AGENTS.md)

This repository follows a strict agent-independent engineering standard. Any coding assistant (Claude Code, Antigravity, Cursor, Copilot) must follow these operational rules.

---

## 1. Single Source of Truth
* All system architecture, domain models, confirmed requirements, and pending questions are recorded in [docs/PROJECT_SPEC.md](file:///Users/dev/P_PROJECT/DEVNAGRI/docs/PROJECT_SPEC.md).
* Manually maintained documentation and generated documentation must never compete:
  * Manually maintained: `docs/product/*`, `docs/architecture/*`, `contracts/openapi.yaml`.
  * Generated: `docs/generated/*`, API client SDKs.
* If source files change, re-analyze only the affected slice. Do not rewrite verified requirements with inferred data.

---

## 2. Directory Layout & Module Ownership

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

## 3. Strict Development Rules

### Rule 1: Concurrency-Safe Bed Allocations
* Every bed allocation must be protected against race conditions using transactional locking (`PESSIMISTIC_WRITE`) and PostgreSQL range exclusion constraints.
* Two residents can never have overlapping active allocations for the same bed.

### Rule 2: Occupancy History Preservation
* Room transfers and departures close allocations with timestamps and audit reasons. They never update or delete historical occupancy records.

### Rule 3: Financial Reconciliation
* Monetary values must use `BigDecimal` and `NUMERIC(12,2)`.
* Invoices, payments, and payment allocations must strictly reconcile.
* Security deposits are liabilities, not rental income.

### Rule 4: Server-Enforced Branch Authorization
* Client-side UI filtering is for user experience only.
* Spring Security policies and service queries must strictly enforce branch authorization boundaries.

### Rule 5: Ponytail Minimal Coding Discipline
* Follow [agent/policies/coding-standards.md](file:///Users/dev/P_PROJECT/DEVNAGRI/agent/policies/coding-standards.md): Prefer existing code, native platform features, and minimal solutions over premature abstractions (YAGNI).
* Never introduce speculative frameworks, redundant layers, or unneeded dependencies.
* Never sacrifice concurrency safety, financial precision, or tests for line-count reduction.

---

## 4. Standard Skill Execution
When instructed to build or modify features, load and execute [agent/skills/implement-feature/SKILL.md](file:///Users/dev/P_PROJECT/DEVNAGRI/agent/skills/implement-feature/SKILL.md).
