#!/usr/bin/env bash
# Expose demo server (API + admin portal) via Cloudflare quick tunnel on port 8090.
# Usage: ./infrastructure/scripts/start-demo-tunnel.sh
set -euo pipefail

PLATFORM_DIR="${PLATFORM_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$PLATFORM_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is required. Install: brew install cloudflared"
  exit 1
fi

GATEWAY_URL="http://127.0.0.1:8090"
if ! curl -sf "${GATEWAY_URL}/health" >/dev/null 2>&1; then
  echo "API gateway not reachable at ${GATEWAY_URL}"
  echo "Deploy first: ./scripts/deploy-demo-server.sh"
  exit 1
fi

URL_FILE="${PLATFORM_DIR}/demo-public-url.txt"
LOG_FILE="${PLATFORM_DIR}/demo-tunnel.log"
SUPERVISOR_PID_FILE="${PLATFORM_DIR}/demo-tunnel-supervisor.pid"

stop_tunnel() {
  screen -S myboss-cf -X quit 2>/dev/null || true
  if [ -f "$SUPERVISOR_PID_FILE" ]; then
    kill "$(cat "$SUPERVISOR_PID_FILE")" 2>/dev/null || true
    rm -f "$SUPERVISOR_PID_FILE"
  fi
  pkill -f "cloudflared tunnel --url http://127.0.0.1:8090" 2>/dev/null || true
  pkill -f "demo-tunnel-supervisor.sh" 2>/dev/null || true
}

stop_tunnel
sleep 2
rm -f "$URL_FILE"
: > "$LOG_FILE"

echo "==> Starting Cloudflare tunnel → ${GATEWAY_URL}"
echo "    Using screen session: myboss-cf (survives terminal close)"
echo ""

MARKER="tunnel-start-$(date -u +%s)"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $MARKER" >> "$LOG_FILE"

screen -dmS myboss-cf bash -c "cloudflared tunnel --url ${GATEWAY_URL} --protocol http2 --no-autoupdate 2>&1 | tee -a ${LOG_FILE}"

PUBLIC_URL=""
for _ in $(seq 1 90); do
  PUBLIC_URL="$(awk "/${MARKER}/{flag=1} flag" "$LOG_FILE" | grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' | tail -1 || true)"
  if [ -n "$PUBLIC_URL" ]; then
    echo "$PUBLIC_URL" > "$URL_FILE"
    break
  fi
  sleep 1
done

if [ -z "$PUBLIC_URL" ]; then
  echo "Tunnel started but URL not ready. Check: tail -f $LOG_FILE"
  exit 1
fi

HTTP_CODE="000"
for _ in $(seq 1 45); do
  HOST="${PUBLIC_URL#https://}"
  IP="$(dig +short @8.8.8.8 "$HOST" 2>/dev/null | head -1)"
  if [ -n "$IP" ]; then
    HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --resolve "${HOST}:443:${IP}" --max-time 15 "${PUBLIC_URL}/health" 2>/dev/null || echo 000)"
  else
    HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${PUBLIC_URL}/health" 2>/dev/null || echo 000)"
  fi
  if [ "$HTTP_CODE" = "200" ]; then
    break
  fi
  sleep 3
done

echo "=========================================="
echo " PUBLIC URL (open on any device):"
echo " ${PUBLIC_URL}"
echo "=========================================="
echo "Mobile:  ${PUBLIC_URL}/app/"
echo "Admin:   ${PUBLIC_URL}/login"
echo "Health:  HTTP ${HTTP_CODE}"
echo "Saved to: demo-public-url.txt"
echo ""
echo "Stop: screen -S myboss-cf -X quit"

if [ "$HTTP_CODE" != "200" ]; then
  echo ""
  echo "WARNING: Tunnel URL not returning 200 yet."
  echo "Check: pgrep -fl cloudflared && screen -ls"
  echo "Logs: tail -f demo-tunnel.log"
  exit 1
fi

# Stability check — must stay up 20s
sleep 10
HTTP2="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${PUBLIC_URL}/health" 2>/dev/null || echo 000)"
sleep 10
HTTP3="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${PUBLIC_URL}/health" 2>/dev/null || echo 000)"
if [ "$HTTP2" != "200" ] || [ "$HTTP3" != "200" ]; then
  echo "FAIL: Tunnel unstable (${HTTP2}, ${HTTP3}). Check memory / cloudflared."
  exit 1
fi
echo "Stability: OK (${HTTP2}, ${HTTP3})"
