#!/usr/bin/env bash
# Start live demo tunnel and print ALL test URLs. Keep this terminal open.
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
GATEWAY="http://127.0.0.1:8090"
LAN=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")

if ! curl -sf "${GATEWAY}/health" >/dev/null; then
  echo "ERROR: Gateway not running on :8090"
  echo "Run: ./scripts/deploy-demo-server.sh && ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh"
  exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Install cloudflared: brew install cloudflared"
  exit 1
fi

pkill -f "cloudflared tunnel --url ${GATEWAY}" 2>/dev/null || true
sleep 2

LOG="$(mktemp /tmp/myboss-cf-XXXX.log)"
echo "Starting Cloudflare tunnel → ${GATEWAY}"
echo "(Keep this window open — closing it stops the public URLs)"
echo ""

cloudflared tunnel --url "${GATEWAY}" --protocol http2 --no-autoupdate 2>&1 | tee "$LOG" &
CF_PID=$!

PUBLIC=""
for _ in $(seq 1 60); do
  PUBLIC=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$LOG" | tail -1)
  if [ -n "$PUBLIC" ]; then
    CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "${PUBLIC}/health" 2>/dev/null || echo 000)
    if [ "$CODE" = "200" ]; then
      echo "$PUBLIC" > demo-public-url.txt
      break
    fi
  fi
  sleep 2
done

if [ -z "$PUBLIC" ]; then
  echo "ERROR: Tunnel URL not ready. See log above."
  kill "$CF_PID" 2>/dev/null || true
  exit 1
fi

echo ""
echo "=========================================="
echo " LIVE DEMO URLs (public internet)"
echo " Base: ${PUBLIC}"
echo "=========================================="
echo ""
echo "Health:     ${PUBLIC}/health"
echo "Admin:      ${PUBLIC}/login"
echo "Employee:   ${PUBLIC}/app/"
echo "Sign-in:    ${PUBLIC}/app/sign-in"
echo ""
echo "Swagger Auth:   ${PUBLIC}/auth/api/v1/docs"
echo "Swagger User:   ${PUBLIC}/user/api/v1/docs"
echo "Swagger Config: ${PUBLIC}/config/api/v1/docs"
echo "Swagger Squad:  ${PUBLIC}/squad/api/v1/docs"
echo "Swagger Survey: ${PUBLIC}/survey/api/v1/docs"
echo ""
if [ -n "$LAN" ]; then
  echo "=========================================="
  echo " Wi‑Fi URLs (same network, no tunnel)"
  echo "=========================================="
  echo "Admin:      http://${LAN}:8090/login"
  echo "Employee:   http://${LAN}:8090/app/"
  echo "Swagger:    http://${LAN}:8090/auth/api/v1/docs"
  echo ""
fi
echo "Logins: admin@orange.com / admin123  |  demo@orange.com + OTP"
echo ""
echo "Press Ctrl+C to stop the tunnel."
echo "=========================================="

wait "$CF_PID"
