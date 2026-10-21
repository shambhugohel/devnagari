#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================================="
echo "    Devnagari PG & Hostel — Automated Verification"
echo "=========================================================="

# 1. OpenAPI Contract Validation
echo ""
echo "1. Validating Canonical OpenAPI Contract (contracts/openapi.yaml)..."
if [ ! -f "$ROOT_DIR/contracts/openapi.yaml" ]; then
    echo "ERROR: contracts/openapi.yaml not found!"
    exit 1
fi
node -e '
const fs = require("fs");
const path = "'"$ROOT_DIR"'/contracts/openapi.yaml";
const content = fs.readFileSync(path, "utf8");
if (!content.includes("openapi: 3.") || !content.includes("paths:") || !content.includes("components:")) {
  console.error("ERROR: contracts/openapi.yaml missing required OpenAPI 3 keys");
  process.exit(1);
}
console.log("✓ contracts/openapi.yaml structure validated");
'

# 2. Database & Container Verification
echo ""
echo "2. Checking Database Connectivity..."
DB_READY=false

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if ! docker exec devnagari-postgres pg_isready -U devnagari -d devnagari_pg >/dev/null 2>&1; then
        echo "Starting devnagari-postgres container via docker compose..."
        docker compose -f "$ROOT_DIR/infra/docker/docker-compose.yml" up -d
        until docker exec devnagari-postgres pg_isready -U devnagari -d devnagari_pg >/dev/null 2>&1; do
            sleep 1
        done
    fi
    DB_READY=true
    TABLE_COUNT=$(docker exec -i devnagari-postgres psql -U devnagari -d devnagari_pg -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo "✓ Database is healthy (found ${TABLE_COUNT// /} tables in public schema)"
elif command -v pg_isready >/dev/null 2>&1 && pg_isready -h localhost -p 5432 -U devnagari -d devnagari_pg >/dev/null 2>&1; then
    DB_READY=true
    echo "✓ Local PostgreSQL is healthy on localhost:5432"
else
    echo "WARNING: PostgreSQL is not running. Integration tests may fail if DB is required."
fi

# 3. Frontend Build & Type Check
echo ""
echo "3. Building Frontend (apps/web)..."
(cd "$ROOT_DIR/apps/web" && npm run build)
echo "✓ Frontend (Vite + React + TypeScript) built successfully"

# 4. Backend Build & Tests via Gradle Wrapper
echo ""
echo "4. Running Backend Tests via Gradle Wrapper (apps/api)..."
(cd "$ROOT_DIR/apps/api" && ./gradlew test)
echo "✓ Backend (Spring Boot 3 + Java 21) passed tests"

echo ""
echo "=========================================================="
echo "    All Verification Checks Passed Successfully! ✓"
echo "=========================================================="
