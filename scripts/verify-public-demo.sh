#!/usr/bin/env bash
# Verify public demo tunnel + gateway are actually working (run before telling user "all done").
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
URL_FILE="${PLATFORM_DIR}/demo-public-url.txt"
GATEWAY="http://127.0.0.1:8090"
FAIL=0

echo "==> Local gateway"
if curl -sf "${GATEWAY}/health" >/dev/null; then
  echo "OK  ${GATEWAY}/health"
else
  echo "FAIL ${GATEWAY}/health"
  FAIL=1
fi

echo ""
echo "==> cloudflared process"
if pgrep -f "cloudflared tunnel --url http://127.0.0.1:8090" >/dev/null; then
  pgrep -fl "cloudflared tunnel" | head -1
else
  echo "FAIL no cloudflared tunnel running"
  FAIL=1
fi

if [ ! -s "$URL_FILE" ]; then
  echo "FAIL demo-public-url.txt missing or empty"
  exit 1
fi

PUBLIC="$(tr -d '[:space:]' < "$URL_FILE")"
echo ""
echo "==> Public URL: $PUBLIC"

for path in /health /login /app/; do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 20 "${PUBLIC}${path}" 2>/dev/null || echo 000)"
  if [ "$CODE" = "200" ]; then
    echo "OK  ${path} ($CODE)"
  else
    echo "FAIL ${path} ($CODE)"
    FAIL=1
  fi
done

echo ""
echo "==> Stability (3 checks, 10s apart)"
for i in 1 2 3; do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 20 "${PUBLIC}/health" 2>/dev/null || echo 000)"
  echo "  check $i: $CODE"
  if [ "$CODE" != "200" ]; then FAIL=1; fi
  [ "$i" -lt 3 ] && sleep 10
done

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "PUBLIC DEMO NOT READY — restart: ./scripts/start-demo-tunnel.sh"
  exit 1
fi

echo ""
echo "All public demo checks passed."
