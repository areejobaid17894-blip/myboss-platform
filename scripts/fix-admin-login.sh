#!/usr/bin/env bash
# Recreate auth-service so DEMO_ADMIN_PASSWORD from .env is applied (restart is not enough).
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
export MYBOSS_ADMIN_DIR="${MYBOSS_ADMIN_DIR:-$PLATFORM_DIR/../myboss-admin}"

echo "==> Rebuilding and recreating auth-service (reload .env)"
docker compose -f docker/docker-compose.demo.yml build auth-service
docker compose -f docker/docker-compose.demo.yml up -d --force-recreate auth-service

sleep 10

echo "==> Admin sign-in test"
curl -sS -X POST http://127.0.0.1:3001/api/v1/auth/admin-sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@orange.com","password":"admin123"}' \
  -w "\nHTTP_STATUS: %{http_code}\n"

echo "==> Rebuilding admin-portal"
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal

echo "Done. Admin: http://127.0.0.1:8081 (Docker) or npm run dev → http://127.0.0.1:5173"
