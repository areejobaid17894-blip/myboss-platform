#!/usr/bin/env bash
# Build and start my boss app demo stack with Docker Compose
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

COMPOSE_FILE="infrastructure/docker/docker-compose.demo.yml"

echo "==> Building and starting my boss app (Docker)..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo ""
echo "==> Containers"
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "Health checks (wait ~30s after first build):"
echo "  ./infrastructure/scripts/verify-backend.sh"
echo ""
echo "Optional admin portal (port 8080):"
echo "  docker compose -f $COMPOSE_FILE --profile with-admin up -d --build admin-portal"
