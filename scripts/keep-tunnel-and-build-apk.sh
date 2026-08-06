#!/usr/bin/env bash
# Run this in Terminal and KEEP THE WINDOW OPEN.
# Starts tunnel, verifies URL, builds external APK with matching URL.
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE_DIR="${MYBOSS_MOBILE_DIR:-$PLATFORM_DIR/../myboss-mobile}"
LAN=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")

cd "$PLATFORM_DIR"

if ! curl -sf http://127.0.0.1:8090/health >/dev/null; then
  echo "ERROR: Gateway not running. Run first:"
  echo "  ./scripts/deploy-demo-server.sh 127.0.0.1"
  echo "  ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh"
  exit 1
fi

echo "==> Starting Cloudflare tunnel (keep this terminal open)..."
CFLOG="$(mktemp /tmp/cf-live-XXXXXX.log)"
cloudflared tunnel --url http://127.0.0.1:8090 --protocol http2 --no-autoupdate >> "$CFLOG" 2>&1 &
CF_PID=$!

URL=""
for _ in $(seq 1 45); do
  if ! kill -0 "$CF_PID" 2>/dev/null; then
    echo "ERROR: cloudflared exited. Log:"
    tail -10 "$CFLOG"
    exit 1
  fi
  URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$CFLOG" | tail -1)
  if [ -n "$URL" ]; then
    HOST="${URL#https://}"
    IP=$(dig +short @8.8.8.8 "$HOST" 2>/dev/null | head -1)
    if [ -n "$IP" ]; then
      CODE=$(curl -s -o /dev/null -w '%{http_code}' --resolve "${HOST}:443:${IP}" --max-time 15 "${URL}/health" 2>/dev/null || echo 000)
      [ "$CODE" = "200" ] && break
    fi
  fi
  sleep 2
done

if [ -z "$URL" ]; then
  echo "ERROR: Tunnel URL not ready. Check demo-tunnel.log"
  kill "$CF_PID" 2>/dev/null || true
  exit 1
fi

HOST="${URL#https://}"
echo "$URL" > demo-public-url.txt

echo "Waiting for tunnel health..."
for _ in $(seq 1 30); do
  IP=$(dig +short @8.8.8.8 "$HOST" 2>/dev/null | head -1)
  if [ -n "$IP" ]; then
    CODE=$(curl -s -o /dev/null -w '%{http_code}' --resolve "${HOST}:443:${IP}" --max-time 15 "${URL}/health" 2>/dev/null || echo 000)
    if [ "$CODE" = "200" ]; then break; fi
  fi
  sleep 2
done

IP=$(dig +short @8.8.8.8 "$HOST" | head -1)
HEALTH=$(curl -s -o /dev/null -w '%{http_code}' --resolve "${HOST}:443:${IP}" "${URL}/health" 2>/dev/null || echo 000)
if [ "$HEALTH" != "200" ]; then
  echo "ERROR: Tunnel not healthy (HTTP $HEALTH)"
  exit 1
fi

echo ""
echo "=========================================="
echo " TUNNEL LIVE — test on phone browser:"
echo " ${URL}/app/"
echo "=========================================="
echo ""

echo "==> Building external APK..."
cd "$MOBILE_DIR"
chmod +x build-external-android.sh 2>/dev/null || true

FLUTTER_BIN="fvm flutter"
command -v fvm >/dev/null 2>&1 || FLUTTER_BIN="flutter"

API_HOSTS="$HOST"
[ -n "$LAN" ] && API_HOSTS="${HOST},${LAN}"

$FLUTTER_BIN build apk --release \
  --dart-define=API_HOSTS="$API_HOSTS" \
  --dart-define=GATEWAY_ORIGIN="$URL" \
  --dart-define=DEMO_MODE=true

mkdir -p build/android-dist
cp build/app/outputs/flutter-apk/app-release.apk build/android-dist/myboss-demo-external.apk
cp build/android-dist/myboss-demo-external.apk /Users/macbookair/Desktop/myboss-demo-external.apk

echo ""
echo "=========================================="
echo " APK READY"
echo "=========================================="
echo "File: /Users/macbookair/Desktop/myboss-demo-external.apk"
echo "Tunnel: $URL"
echo "WiFi fallback: http://${LAN}:8090"
echo "Login: demo@orange.com + OTP"
echo ""
echo "IMPORTANT: Do NOT close this terminal — tunnel stops if cloudflared exits."
echo "Press Ctrl+C to stop tunnel when done."
echo "=========================================="

wait "$CF_PID"
