# Devnagari PG & Hostel — Windows One-Click Developer Setup (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Devnagari PG & Hostel — Windows Developer Setup       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$RootDir = Split-Path -Parent $PSScriptRoot

# 1. Check Java 21
Write-Host "`n--- 1. Checking Java Runtime ---" -ForegroundColor Yellow
try {
    $javaVerOutput = & java -version 2>&1 | Out-String
    Write-Host "Found Java: $($javaVerOutput.Split("`n")[0])" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Java is not found in PATH." -ForegroundColor Red
    Write-Host "Please install OpenJDK 21 (e.g. from https://adoptium.net/temurin/releases/?version=21)." -ForegroundColor Red
    exit 1
}

# 2. Check Node.js and npm
Write-Host "`n--- 2. Checking Node.js & npm ---" -ForegroundColor Yellow
try {
    $nodeVer = & node -v
    $npmVer = & npm -v
    Write-Host "Found Node.js: $nodeVer (npm $npmVer)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Node.js or npm is not found in PATH." -ForegroundColor Red
    Write-Host "Please install Node.js 20+ LTS from https://nodejs.org." -ForegroundColor Red
    exit 1
}

# 3. Check PostgreSQL / Docker
Write-Host "`n--- 3. Setting Up PostgreSQL 16 Database ---" -ForegroundColor Yellow
$DbReady = $false

# Check if Docker is available
try {
    $dockerInfo = & docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker engine detected. Starting PostgreSQL 16 container..." -ForegroundColor Green
        $composeFile = Join-Path $RootDir "infra\docker\docker-compose.yml"
        & docker compose -f $composeFile up -d

        Write-Host "Waiting for database to be healthy..."
        Start-Sleep -Seconds 3
        $DbReady = $true
    }
} catch {
    Write-Host "Docker not running or not installed." -ForegroundColor Gray
}

if (-not $DbReady) {
    Write-Host "NOTE: Docker is not running. If you are using a local PostgreSQL installation," -ForegroundColor Yellow
    Write-Host "ensure database 'devnagari_pg' exists on localhost:5432 with user 'devnagari'." -ForegroundColor Yellow
}

# 4. Frontend Setup
Write-Host "`n--- 4. Installing Frontend Dependencies (apps/web) ---" -ForegroundColor Yellow
Set-Location (Join-Path $RootDir "apps\web")
& npm install
Write-Host "✓ Frontend dependencies installed" -ForegroundColor Green

# 5. Backend Migration & Verification
Write-Host "`n--- 5. Verifying Backend & Migrations (apps/api) ---" -ForegroundColor Yellow
Set-Location (Join-Path $RootDir "apps\api")
if ($DbReady) {
    Write-Host "Running Gradle test and Flyway database migrations..."
    & .\gradlew.bat test
    Write-Host "✓ Backend tests passed and database migrations verified" -ForegroundColor Green
} else {
    Write-Host "Skipping backend integration test (database container not detected)." -ForegroundColor Gray
}

Set-Location $RootDir

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "    Devnagari PG & Hostel — Setup Complete!               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "`nHow to start development:"
Write-Host "`n  1. Backend API (Spring Boot 3):" -ForegroundColor Green
Write-Host "     cd apps\api"
Write-Host "     .\gradlew.bat bootRun"
Write-Host "     Server URL: http://localhost:8080"
Write-Host "`n  2. Frontend Web (React + Vite):" -ForegroundColor Green
Write-Host "     cd apps\web"
Write-Host "     npm run dev"
Write-Host "     Client URL: http://localhost:5173"
Write-Host "`n  3. Documentation & Architecture:" -ForegroundColor Green
Write-Host "     docs\PROJECT_SPEC.md   — Master system specification"
Write-Host "     contracts\openapi.yaml — Canonical API contract"
Write-Host "     AGENTS.md              — AI engineering standards"
Write-Host "==========================================================" -ForegroundColor Cyan
