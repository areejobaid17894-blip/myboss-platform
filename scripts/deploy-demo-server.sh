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

# Ensure demo admin password matches UI pre-fill (admin123)
if grep -q '^DEMO_ADMIN_PASSWORD=change-me' .env 2>/dev/null; then
  sed -i '' 's/^DEMO_ADMIN_PASSWORD=change-me/DEMO_ADMIN_PASSWORD=admin123/' .env
fi

echo "==> Backend: $MYBOSS_BACKEND_DIR"
echo "==> Admin:   $MYBOSS_ADMIN_DIR"
echo "==> DEMO_HOST: $DEMO_HOST"

docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml up -d --force-recreate auth-service
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal

if [ "${SKIP_GATEWAY:-}" != "1" ]; then
  echo "==> Starting API gateway on :8090"
  ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
fi

sleep 15
./scripts/verify-backend.sh || true
echo "Demo ready — gateway :8090 (run deploy-mobile-web.sh after backend)"
