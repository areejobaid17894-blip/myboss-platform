#!/usr/bin/env bash
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
docker compose -f docker/docker-compose.demo.yml up -d --build user-service survey-service
docker compose -f docker/docker-compose.demo.yml restart auth-service squad-service
sleep 8
./scripts/verify-backend.sh || true
echo "Demo data reset complete."
