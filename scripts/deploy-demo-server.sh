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

if grep -q '^DEMO_ADMIN_PASSWORD=change-me' .env 2>/dev/null; then
  sed -i '' 's/^DEMO_ADMIN_PASSWORD=change-me/DEMO_ADMIN_PASSWORD=admin123/' .env
fi

echo "==> Backend: $MYBOSS_BACKEND_DIR"
echo "==> Admin:   $MYBOSS_ADMIN_DIR"
echo "==> DEMO_HOST: $DEMO_HOST"
echo "==> APIs: direct service ports :3001–3006 (no Apigee)"

docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml up -d --force-recreate auth-service
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal

sleep 15
./scripts/verify-backend.sh || true
./scripts/verify-mobile-api.sh 127.0.0.1 || true

echo ""
echo "Demo ready (no nginx):"
echo "  Backend ports :3001–3006"
echo "  Admin UI      http://127.0.0.1:8081  (direct ports — DEMO_HOST=${DEMO_HOST})"
echo "  Admin dev     cd ../myboss-admin && npm run dev  → http://127.0.0.1:5173"
echo "  Mobile dev    cd ../myboss-mobile && fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true"
