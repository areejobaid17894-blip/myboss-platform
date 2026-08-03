#!/usr/bin/env bash
# Expose the admin portal (port 8081) via Cloudflare quick tunnel.
# Works when lab/campus Wi‑Fi blocks device-to-device access.
# Usage: ./infrastructure/scripts/start-demo-admin-tunnel.sh
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is required. Install: brew install cloudflared"
  exit 1
fi

ADMIN_URL="http://127.0.0.1:8081"
if ! curl -sf "${ADMIN_URL}/health" >/dev/null 2>&1; then
  echo "Admin portal not reachable at ${ADMIN_URL}"
  echo "Deploy first: ./infrastructure/scripts/deploy-demo-server.sh"
  exit 1
fi

URL_FILE="${REPO_DIR}/admin-public-url.txt"
LOG_FILE="${REPO_DIR}/admin-tunnel.log"

echo "==> Starting Cloudflare tunnel → ${ADMIN_URL}"
echo "    Waiting for public URL..."
echo ""

: > "$LOG_FILE"

cloudflared tunnel --url "${ADMIN_URL}" 2>&1 | tee "$LOG_FILE" | while IFS= read -r line; do
  if [[ "$line" =~ https://[a-zA-Z0-9-]+\.trycloudflare\.com ]]; then
    PUBLIC_URL="${BASH_REMATCH[0]}"
    echo "$PUBLIC_URL" > "$URL_FILE"
    echo ""
    echo "=========================================="
    echo " ADMIN PUBLIC URL (open on any device):"
    echo " ${PUBLIC_URL}"
    echo "=========================================="
    echo "Saved to: admin-public-url.txt"
    echo "Login: admin@orange.com / admin123"
    echo "Press Ctrl+C to stop the tunnel."
    echo ""
  fi
  printf '%s\n' "$line"
done
