# Devnagari PG & Hostel — Management System

> Production-grade property management platform for **Devnagari PG & Hostel** across 5 branches (Sector 8B, Sector 1 Girls, 317 Sector 8B Girls, Aashka Raysan, Koba Raysan).
> Architected as a **Modular Monolith** with strict concurrency safety, financial reconciliation, and branch isolation.

---

## 🚀 1-Minute Developer Quickstart

Whether you are on **macOS**, **Linux**, or **Windows**, clone the repository and run the single setup command:

### On macOS / Linux / WSL / Git Bash:
```bash
./setup.sh
```

### On Windows (Command Prompt or PowerShell):
```cmd
setup.bat
```
*(Or in PowerShell: `powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1`)*

The setup script automatically:
1. Detects your OS and verifies **Java 21+** and **Node.js 20+**.
2. Checks for local PostgreSQL or starts **PostgreSQL 16 Alpine** with `btree_gist` and `uuid-ossp` extensions via **OrbStack / Docker**.
3. Installs frontend dependencies in `apps/web`.
4. Runs backend Flyway migrations and verifies tests in `apps/api`.

---

## 💻 Running Locally

### 1. Start the Database (if not already running)
```bash
# macOS/Linux/WSL
./scripts/dev-up.sh

# Or with Docker Compose directly
docker compose -f infra/docker/docker-compose.yml up -d
```

### 2. Start the Backend API (Spring Boot 3 + Java 21)
```bash
cd apps/api

# macOS/Linux
./gradlew bootRun

# Windows
.\gradlew.bat bootRun
```
* API Server: `http://localhost:8080/api/v1`
* Health Check: `http://localhost:8080/actuator/health`

### 3. Start the Frontend App (React + Vite + TypeScript)
```bash
cd apps/web
npm run dev
```
* Web App: `http://localhost:5173`

---

## 📁 Repository Structure

```
devnagari-pg/
├── setup.sh                   # One-click developer setup (macOS/Linux/WSL)
├── setup.bat                  # One-click developer setup (Windows)
├── AGENTS.md                  # Authoritative AI engineering operating standard
├── CLAUDE.md                  # Thin adapter for Claude Code
├── apps/
│   ├── api/                   # Java 21 + Spring Boot 3 modular monolith
│   │   └── src/main/resources/db/migration/ # Flyway V1 schema (74 tables)
│   └── web/                   # React + TypeScript + Vite frontend
├── contracts/
│   └── openapi.yaml           # Canonical OpenAPI 3.0 REST contract
├── docs/
│   ├── PROJECT_SPEC.md        # Master system specification (Single source of truth)
│   ├── architecture/          # Domain model, ER diagrams, and ADRs
│   └── product/               # Business rules, roles, and UI workflows
├── agent/
│   ├── policies/              # Coding standards (Ponytail principles)
│   └── skills/                # Standard agent workflow skills
├── infra/
│   └── docker/                # PostgreSQL 16 docker-compose setup
└── scripts/
    ├── setup.sh               # Cross-platform Unix setup
    ├── setup.ps1              # Cross-platform Windows PowerShell setup
    ├── dev-up.sh              # Container startup
    └── verify.sh              # Full end-to-end verification pipeline
```

---

## 🏛 Architecture: Package-by-Feature (Modular Monolith)

The backend follows a **Package-by-Feature** architecture (`com.devnagari.pg.<domain>`):

```
com.devnagari.pg/
├── shared/                    # Common value objects, money utils, security context
├── identity/                  # Staff users, tenant auth, branch assignments
├── accommodation/             # Branches, rooms, sharing types, beds
├── onboarding/                # Inquiries, stays, bed allocations, check-ins
├── billing/                   # Charges, payments, payment allocations, cash book
├── maintenance/               # Complaints, inventory, asset tracking
└── housekeeping/              # Cleaning checklist, inspection verifications
```

### Why Package-by-Feature?
1. **High Cohesion, Low Coupling:** Everything required for a business capability (Controller, Service, Entity, Repository, DTOs) lives inside its own bounded module.
2. **Microservices Ready:** Because boundaries are clean and isolated, extracting any domain (e.g., `billing` or `housekeeping`) into a standalone microservice later requires **zero refactoring of business logic**—just moving the package into its own service repo or Gradle submodule.
3. **No Unneeded Indirection (Ponytail Discipline):**
   - Spring Data JPA `Repository` interfaces replace outdated DAO/DAOImpl boilerplate.
   - We avoid anemic `Service` / `ServiceImpl` pairs unless polymorphic substitution is actually needed.

---

## 🛡 Inviolable Engineering Rules

Any developer or AI coding assistant working on this codebase must adhere to:

1. **Rule 1: Concurrency-Safe Bed Allocations**  
   Every bed allocation must use `PESSIMISTIC_WRITE` locking and PostgreSQL range exclusion constraints (`btree_gist` index `no_overlapping_bed_stays`). Double booking is strictly impossible.
2. **Rule 2: Occupancy History Preservation**  
   Room transfers and departures close allocations with timestamps and audit reasons. Historical records are never updated or deleted.
3. **Rule 3: Financial Reconciliation**  
   Monetary values strictly use `BigDecimal` and `NUMERIC(12,2)`. Invoices (`charges`), receipts (`payments`), and allocations must reconcile to the paisa. Security deposits are balance-sheet liabilities, never rental income.
4. **Rule 4: Server-Enforced Branch Authorization**  
   UI filtering is for display only; Spring Security and SQL queries must strictly enforce branch scoping.
5. **Rule 5: UIDAI Aadhaar Compliance**  
   Raw Aadhaar numbers must never be stored. Store only masked strings (`XXXX-XXXX-1234`) and object-storage UUID pointers for scanned files.

---

## 🔄 Keeping Documentation & Code in Sync

This project maintains a **Document-First Workflow**:
- When business rules, pricing logic, or UI workflows change, update [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md).
- When API endpoints change, update [contracts/openapi.yaml](contracts/openapi.yaml).
- When database tables change, add a new Flyway migration (`V2__...sql`) and update [docs/architecture/domain-model.md](docs/architecture/domain-model.md).
- Run `./scripts/verify.sh` to validate the full stack before submitting PRs.

