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
  if [ -f "$SUPERVISOR_PID_FILE" ]; then
    kill "$(cat "$SUPERVISOR_PID_FILE")" 2>/dev/null || true
    rm -f "$SUPERVISOR_PID_FILE"
  fi
  pkill -f "cloudflared tunnel --url http://127.0.0.1:8090" 2>/dev/null || true
  pkill -f "demo-tunnel-supervisor.sh" 2>/dev/null || true
}

stop_tunnel
sleep 2
: > "$LOG_FILE"
rm -f "$URL_FILE"

echo "==> Starting Cloudflare tunnel → ${GATEWAY_URL}"
echo ""
echo "IMPORTANT: Keep this terminal open, or run in tmux/screen."
echo "Quick tunnels stop when cloudflared exits."
echo ""

chmod +x "$SCRIPT_DIR/demo-tunnel-supervisor.sh"
# setsid + nohup keeps tunnel alive after the terminal closes
if command -v setsid >/dev/null 2>&1; then
  setsid nohup "$SCRIPT_DIR/demo-tunnel-supervisor.sh" >> "$LOG_FILE" 2>&1 &
else
  nohup "$SCRIPT_DIR/demo-tunnel-supervisor.sh" >> "$LOG_FILE" 2>&1 &
fi
SUPERVISOR_PID=$!
echo "$SUPERVISOR_PID" > "$SUPERVISOR_PID_FILE"
disown "$SUPERVISOR_PID" 2>/dev/null || true

PUBLIC_URL=""
for _ in $(seq 1 90); do
  if [ -f "$URL_FILE" ] && [ -s "$URL_FILE" ]; then
    PUBLIC_URL="$(tr -d '[:space:]' < "$URL_FILE")"
    break
  fi
  sleep 1
done

if [ -z "$PUBLIC_URL" ]; then
  echo "Tunnel started but URL not ready. Check: tail -f $LOG_FILE"
  exit 1
fi

HTTP_CODE="000"
for _ in $(seq 1 30); do
  HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' "${PUBLIC_URL}/health" 2>/dev/null || echo 000)"
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
echo "Stop: kill \$(cat demo-tunnel-supervisor.pid)"

if [ "$HTTP_CODE" != "200" ]; then
  echo ""
  echo "WARNING: Tunnel URL not returning 200 yet."
  echo "Check cloudflared is running: pgrep -fl cloudflared"
  echo "Logs: tail -f demo-tunnel.log"
  exit 1
fi
