#!/usr/bin/env bash
# Internal supervisor — keeps cloudflared running and updates demo-public-url.txt
set -uo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

GATEWAY_URL="http://127.0.0.1:8090"
URL_FILE="${REPO_DIR}/demo-public-url.txt"
LOG_FILE="${REPO_DIR}/demo-tunnel.log"
PID_FILE="${REPO_DIR}/demo-tunnel.pid"

write_url_from_log() {
  local marker="$1"
  awk "/${marker}/{flag=1} flag" "$LOG_FILE" \
    | grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' \
    | tail -1
}

while true; do
  MARKER="tunnel-start-$(date -u +%s)"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] starting cloudflared ($MARKER)" >> "$LOG_FILE"

  (
    for _ in $(seq 1 90); do
      PUBLIC_URL="$(write_url_from_log "$MARKER")"
      if [ -n "$PUBLIC_URL" ]; then
        echo "$PUBLIC_URL" > "$URL_FILE"
        exit 0
      fi
      sleep 1
    done
  ) &
  WATCHER_PID=$!

  # Run in foreground so the supervisor reliably waits; nohup/setsid keeps us alive after terminal exit.
  cloudflared tunnel --url "${GATEWAY_URL}" --protocol http2 --no-autoupdate >> "$LOG_FILE" 2>&1 &
  CF_PID=$!
  echo "$CF_PID" > "$PID_FILE"

  wait "$CF_PID" 2>/dev/null || true
  kill "$WATCHER_PID" 2>/dev/null || true
  rm -f "$PID_FILE"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] cloudflared exited (pid=$CF_PID), restarting in 5s" >> "$LOG_FILE"
  sleep 5
done
