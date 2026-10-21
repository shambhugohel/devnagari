---
name: code-review
description: Code review and audit workflow based on Ponytail principles and Devnagari domain safety rules.
---

# Code Review & Audit Workflow

Perform this checklist on pull requests and code modifications:

## 1. Ponytail Minimal Code Checklist
- [ ] **Necessity:** Does every added class, helper, and dependency solve an actual business requirement?
- [ ] **Duplication:** Are there existing components or utilities in the codebase that solve this?
- [ ] **Native Features:** Are native language/browser features used instead of external libraries?
- [ ] **Abstraction Depth:** Is there unnecessary indirection (e.g. single-implementation interfaces, deep DTO hierarchies)?

## 2. Inviolable Domain Checks
- [ ] **Concurrency:** Are bed allocations protected by `PESSIMISTIC_WRITE` and database exclusion constraints?
- [ ] **Financial Precision:** Are all money calculations using `BigDecimal` and stored as `NUMERIC(12,2)`?
- [ ] **Branch Authorization:** Are queries filtered by the authenticated user's assigned branches?
- [ ] **UIDAI Aadhaar:** Is Aadhaar number never stored in plaintext (masked `XXXX-XXXX-1234` only)?
- [ ] **Occupancy Immutability:** Are room transfers closing old records with timestamps rather than deleting them?
