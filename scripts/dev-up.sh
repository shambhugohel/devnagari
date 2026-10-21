#!/usr/bin/env bash
set -euo pipefail

echo "=== Starting Devnagari PG Local Environment (OrbStack) ==="

# Check OrbStack / Docker availability
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Docker/OrbStack daemon. Ensure OrbStack is running."
    exit 1
fi

COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/infra/docker/docker-compose.yml"

echo "Starting PostgreSQL 16 via OrbStack..."
docker compose -f "$COMPOSE_FILE" up -d

echo "Waiting for PostgreSQL to be ready..."
until docker exec devnagari-postgres pg_isready -U devnagari -d devnagari_pg >/dev/null 2>&1; do
    sleep 1
done

echo "PostgreSQL 16 is ready on localhost:5432 (database: devnagari_pg, user: devnagari)"
