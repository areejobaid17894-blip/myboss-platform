#!/usr/bin/env bash
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
export MYBOSS_ADMIN_DIR="${MYBOSS_ADMIN_DIR:-$PLATFORM_DIR/../myboss-admin}"

if [ -n "${1:-}" ]; then export DEMO_HOST="$1"
elif [ -z "${DEMO_HOST:-}" ]; then
  DEMO_HOST="$(curl -fsS --max-time 5 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo localhost)"
  export DEMO_HOST
fi

[ -f .env ] || cp .env.example .env

echo "==> Backend: $MYBOSS_BACKEND_DIR"
echo "==> Admin:   $MYBOSS_ADMIN_DIR"
echo "==> DEMO_HOST: $DEMO_HOST"

docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal

sleep 15
./scripts/verify-backend.sh || true
echo "Demo ready — gateway :8090 (run deploy-mobile-web.sh after backend)"
