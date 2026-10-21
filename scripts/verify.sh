#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " Devnagari PG & Hostel — Verification"
echo "=========================================="

echo "1. Checking OrbStack & PostgreSQL 16 Container..."
if ! docker exec devnagari-postgres pg_isready -U devnagari -d devnagari_pg >/dev/null 2>&1; then
    echo "ERROR: devnagari-postgres container is not ready. Run ./scripts/dev-up.sh first."
    exit 1
fi
echo "✓ PostgreSQL 16 is healthy on port 5432"

echo "2. Checking PostgreSQL Table Count..."
TABLE_COUNT=$(docker exec -i devnagari-postgres psql -U devnagari -d devnagari_pg -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
echo "✓ Found ${TABLE_COUNT// /} tables in public schema"

echo "3. Building Frontend (apps/web)..."
(cd apps/web && npm run build >/dev/null)
echo "✓ Frontend (Vite + React + TypeScript) built successfully"

echo "4. Running Backend Tests (apps/api)..."
(cd apps/api && gradle test >/dev/null)
echo "✓ Backend (Spring Boot 3 + Java 21) passed tests"

echo "=========================================="
echo " All systems verified successfully! ✓"
echo "=========================================="
