#!/usr/bin/env bash
# Internal supervisor — keeps cloudflared running and updates demo-public-url.txt
set -uo pipefail

PLATFORM_DIR="${PLATFORM_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$PLATFORM_DIR"

GATEWAY_URL="http://127.0.0.1:8090"
URL_FILE="${PLATFORM_DIR}/demo-public-url.txt"
LOG_FILE="${PLATFORM_DIR}/demo-tunnel.log"
PID_FILE="${PLATFORM_DIR}/demo-tunnel.pid"

write_url_from_log() {
  local marker="$1"
  awk "/${marker}/{flag=1} flag" "$LOG_FILE" \
    | grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' \
    | tail -1
}

while true; do
  MARKER="tunnel-start-$(date -u +%s)"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] starting cloudflared ($MARKER)" >> "$LOG_FILE"

  cloudflared tunnel --url "${GATEWAY_URL}" --protocol http2 --no-autoupdate >> "$LOG_FILE" 2>&1 &
  CF_PID=$!
  echo "$CF_PID" > "$PID_FILE"

  (
    while kill -0 "$CF_PID" 2>/dev/null; do
      PUBLIC_URL="$(write_url_from_log "$MARKER")"
      if [ -n "$PUBLIC_URL" ]; then
        echo "$PUBLIC_URL" > "$URL_FILE"
      fi
      sleep 3
    done
  ) &
  WATCHER_PID=$!

  wait "$CF_PID" 2>/dev/null || true
  kill "$WATCHER_PID" 2>/dev/null || true
  rm -f "$PID_FILE"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] cloudflared exited (pid=$CF_PID), restarting in 5s" >> "$LOG_FILE"
  sleep 5
done
