# Devnagari PG & Hostel — Coding Standards & Ponytail Principles

> **Core Philosophy:** Prefer existing functionality, native platform features, and minimal solutions over unnecessary abstractions. Spend engineering effort on the property-management product, not on accidental complexity.

---

## 1. The Ponytail Decision Hierarchy

Before writing any new function, class, component, or utility, evaluate in this order:

1. **Does this functionality actually need to exist?**
   * Reject speculative features, premature optimizations, and hypothetical future extensions (YAGNI).
2. **Does the project already have something that solves this?**
   * Search existing components in `apps/web/src/components/ui/` or services in `apps/api/src/main/java/com/devnagari/pg/shared/`. Reuse before creating.
3. **Can the language or runtime platform provide it natively?**
   * *Frontend:* Use native HTML5 inputs (e.g., `<input type="date">`, `<dialog>`, `<form>`) and standard Web APIs before pulling in heavy third-party widget libraries.
   * *Backend:* Use Java standard library features (`java.time.*`, `java.util.stream.*`, records) before introducing utility libraries.
4. **Is an existing library/dependency sufficient?**
   * Reuse libraries already in `package.json` or `build.gradle.kts`. Do not introduce a new dependency for a single trivial helper function.
5. **Only then, write the minimum necessary code.**
   * Keep implementations concise, readable, and direct. Avoid creating 5-layer abstraction hierarchies for straightforward CRUD or mapping tasks.

---

## 2. Inviolable Guardrails (Never Sacrificed for Brevity)

Minimal code must never compromise correctness or safety:

1. **Transactional & Concurrency Safety:**
   * Never drop `@Transactional`, pessimistic locking (`PESSIMISTIC_WRITE`), or PostgreSQL exclusion constraints to reduce lines of code. Bed allocation double-booking prevention is non-negotiable.
2. **Financial Precision:**
   * Never substitute floating-point numbers (`float`, `double`) for `BigDecimal` and `NUMERIC(12,2)`. Every rupee and paisa must reconcile.
3. **Server-Enforced Authorization:**
   * Never rely solely on client-side React UI hiding for security. Spring Security and SQL queries must strictly enforce branch scoping.
4. **Validation & Error Handling:**
   * Never omit input validation, null checks on API boundaries, or descriptive error responses to make code shorter.
5. **Automated Testing:**
   * Minimum code does not mean zero tests. Unit and integration tests must cover core domain rules, race condition safety, and payment allocations.

---

## 3. Frontend Guidelines (`apps/web`)

* **State Management:** Rely on TanStack Query for server state and standard React `useState`/`useReducer` for local UI state. Do not add global stores (Redux, Zustand) unless proven necessary.
* **Component Granularity:** Keep components focused on their business feature (`src/features/<feature>/`). Extract shared components to `src/components/ui/` only when reused across 2+ distinct features.
* **CSS & Design Tokens:** Use clean, consistent CSS variables and utility classes. Avoid heavy CSS-in-JS runtimes.

---

## 4. Backend Guidelines (`apps/api`)

* **Layering:** Package by business capability (`com.devnagari.pg.<domain>`). A domain package typically contains:
  * API Controller & DTOs
  * Application / Domain Service
  * Domain Entity & Repository
* **Avoid Anemic Indirection:** Do not create redundant interfaces where there is only ever one implementation (e.g., avoid `ResidentServiceImpl` implementing `ResidentService` unless polymorphic substitution is actually needed).
* **DTO Mappings:** Use straightforward record constructors or simple mapping methods. Avoid heavy reflection-based mapping frameworks unless mapping volume demonstrably warrants it.
