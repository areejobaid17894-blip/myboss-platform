#!/usr/bin/env bash
# Full pipeline: backend + admin + mobile web + tunnel + external APK
set -euo pipefail

LOG="${MYBOSS_BUILD_LOG:-/Users/macbookair/Desktop/myboss-build.log}"
exec > >(tee -a "$LOG") 2>&1

echo "=== myboss full build started $(date) ==="

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE_DIR="${MYBOSS_MOBILE_DIR:-$PLATFORM_DIR/../myboss-mobile}"
APK_OUT="/Users/macbookair/Desktop/myboss-demo-external.apk"

command -v docker >/dev/null || { echo "ERROR: docker not found"; exit 1; }
command -v cloudflared >/dev/null || { echo "ERROR: cloudflared not found (brew install cloudflared)"; exit 1; }

cd "$PLATFORM_DIR"
[ -f .env ] || cp .env.example .env
chmod +x scripts/*.sh

echo "==> Step 1: Backend + admin (Docker)"
./scripts/deploy-demo-server.sh 127.0.0.1

echo "==> Step 2: Mobile web + gateway :8090"
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh

echo "==> Step 3: Verify backend"
./scripts/verify-backend.sh

echo "==> Step 4: Cloudflare tunnel"
./scripts/start-demo-tunnel.sh

URL_FILE="$PLATFORM_DIR/demo-public-url.txt"
for i in $(seq 1 60); do
  if [ -s "$URL_FILE" ]; then break; fi
  sleep 2
done
TUNNEL_URL="$(tr -d '[:space:]' < "$URL_FILE" 2>/dev/null || true)"
if [ -z "$TUNNEL_URL" ]; then
  echo "ERROR: tunnel URL not ready — check demo-tunnel.log"
  exit 1
fi
echo "Tunnel URL: $TUNNEL_URL"

echo "==> Step 5: External Android APK"
cd "$MOBILE_DIR"
chmod +x build-external-android.sh
./build-external-android.sh

SRC="$MOBILE_DIR/build/android-dist/myboss-demo-external.apk"
cp -f "$SRC" "$APK_OUT"

echo ""
echo "=========================================="
echo " BUILD COMPLETE"
echo "=========================================="
echo "Tunnel:    $TUNNEL_URL"
echo "Admin:     $TUNNEL_URL/login"
echo "Mobile:    $TUNNEL_URL/app/"
echo "APK:       $APK_OUT"
echo "APK size:  $(du -h "$APK_OUT" | cut -f1)"
echo "Login:     admin@orange.com / admin123 (admin)"
echo "           demo@orange.com + OTP (mobile app)"
echo "Keep Mac awake + cloudflared running."
echo "=========================================="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
