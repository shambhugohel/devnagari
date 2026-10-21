#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "    Devnagari PG & Hostel — One-Click Developer Setup     "
echo "=========================================================="

OS="$(uname -s)"
echo "Detected Operating System: $OS"

# 1. Check Java 21
echo ""
echo "--- 1. Checking Java Runtime ---"
if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Found Java version: $JAVA_VER"
    JAVA_MAJOR=$(echo "$JAVA_VER" | cut -d'.' -f1)
    if [ "$JAVA_MAJOR" -lt 21 ]; then
        echo "WARNING: Java 21+ is recommended. Found major version $JAVA_MAJOR."
    else
        echo "✓ Java version meets requirement (21+)"
    fi
else
    echo "ERROR: Java is not installed or not in PATH."
    echo "Please install OpenJDK 21 (e.g. via Homebrew: 'brew install openjdk@21' or adoptium.net)."
    exit 1
fi

# 2. Check Node.js and npm
echo ""
echo "--- 2. Checking Node.js & npm ---"
if command -v node >/dev/null 2>&1; then
    NODE_VER=$(node -v)
    echo "Found Node.js: $NODE_VER"
    NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "WARNING: Node.js 20+ (LTS) is recommended. Found $NODE_VER."
    else
        echo "✓ Node.js meets requirement (20+ LTS)"
    fi
else
    echo "ERROR: Node.js is not installed. Please install Node.js 20+ (https://nodejs.org)."
    exit 1
fi

if command -v npm >/dev/null 2>&1; then
    echo "✓ npm is installed ($(npm -v))"
else
    echo "ERROR: npm is not installed."
    exit 1
fi

# 3. Check Container Runtime & Start PostgreSQL
echo ""
echo "--- 3. Setting Up PostgreSQL 16 Database ---"

DB_CONTAINER="devnagari-postgres"
DB_READY=false

# Check if local postgres is already running and accessible
if command -v pg_isready >/dev/null 2>&1; then
    if pg_isready -h localhost -p 5432 -U devnagari -d devnagari_pg >/dev/null 2>&1; then
        echo "✓ Local PostgreSQL is already running on localhost:5432 and accepting connections"
        DB_READY=true
    fi
fi

if [ "$DB_READY" = false ]; then
    # Check if Docker or OrbStack daemon is available
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        if command -v orb >/dev/null 2>&1; then
            echo "Detected container engine: OrbStack"
        else
            echo "Detected container engine: Docker"
        fi

        COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/infra/docker/docker-compose.yml"
        echo "Starting PostgreSQL 16 container via docker compose..."
        docker compose -f "$COMPOSE_FILE" up -d

        echo "Waiting for PostgreSQL to be ready..."
        until docker exec "$DB_CONTAINER" pg_isready -U devnagari -d devnagari_pg >/dev/null 2>&1; do
            sleep 1
        done
        echo "✓ PostgreSQL container ($DB_CONTAINER) is running and healthy on localhost:5432"
        DB_READY=true
    else
        echo "WARNING: Docker or OrbStack is not running and no local PostgreSQL was detected on port 5432."
        echo "Please start Docker Desktop, OrbStack, or a local PostgreSQL 16 instance with credentials:"
        echo "  Host: localhost | Port: 5432 | DB: devnagari_pg | User: devnagari | Pass: devnagari_secret"
    fi
fi

# 4. Frontend Setup
echo ""
echo "--- 4. Installing Frontend Dependencies (apps/web) ---"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/apps/web"
npm install
echo "✓ Frontend dependencies installed"

# 5. Backend Migration & Test Verification
echo ""
echo "--- 5. Verifying Backend & Migrations (apps/api) ---"
cd "$ROOT_DIR/apps/api"
if [ "$DB_READY" = true ]; then
    echo "Running Gradle build and Flyway database migrations..."
    ./gradlew test
    echo "✓ Backend tests passed and database migrations verified"
else
    echo "Skipping backend integration test (database is not running yet)."
fi

# Done
echo ""
echo "=========================================================="
echo "    Devnagari PG & Hostel — Setup Complete!               "
echo "=========================================================="
echo ""
echo "How to start development:"
echo ""
echo "  1. Backend API (Spring Boot 3):"
echo "     cd apps/api"
echo "     ./gradlew bootRun"
echo "     Server will start at: http://localhost:8080"
echo ""
echo "  2. Frontend Web (React + Vite):"
echo "     cd apps/web"
echo "     npm run dev"
echo "     Client will start at: http://localhost:5173"
echo ""
echo "  3. Master Spec & API Contracts:"
echo "     docs/PROJECT_SPEC.md   — Master operational specification"
echo "     contracts/openapi.yaml — Canonical API contract"
echo "     AGENTS.md              — AI engineering standards & rules"
echo "=========================================================="
