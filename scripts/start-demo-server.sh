#!/usr/bin/env bash
# Build and start my boss app demo stack with Docker Compose
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
export MYBOSS_ADMIN_DIR="${MYBOSS_ADMIN_DIR:-$PLATFORM_DIR/../myboss-admin}"

COMPOSE_FILE="docker/docker-compose.demo.yml"

[ -f .env ] || cp .env.example .env

echo "==> Building and starting my boss app (Docker)..."
docker compose -f "$COMPOSE_FILE" up -d --build
docker compose -f "$COMPOSE_FILE" --profile with-admin up -d --build admin-portal

echo ""
echo "==> Containers"
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "Health checks (wait ~30s after first build):"
echo "  ./scripts/verify-backend.sh"
echo ""
echo "Mobile web + gateway:"
echo "  ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh"
