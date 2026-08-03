#!/usr/bin/env bash
# Expose admin + employee demo outside this laptop (Cloudflare tunnel → gateway :8090).
# Usage: ./infrastructure/scripts/run-external-demo.sh
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

if ! curl -sf http://127.0.0.1:8090/health >/dev/null; then
  echo "Gateway not running. Start stack first:"
  echo "  ./infrastructure/scripts/deploy-demo-server.sh"
  exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Install cloudflared: brew install cloudflared"
  exit 1
fi

LAN="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")"

echo "=========================================="
echo " EXTERNAL DEMO ACCESS"
echo "=========================================="
echo ""
echo "Same Wi‑Fi (phone/tablet near laptop):"
if [ -n "$LAN" ]; then
  echo "  Admin:     http://${LAN}:8090/login"
  echo "  Employee:  http://${LAN}:8090/app/"
else
  echo "  (LAN IP not found — use cloud URLs below)"
fi
echo ""
echo "Starting Cloudflare tunnel (keep this Mac awake)..."
echo ""

exec cloudflared tunnel --url http://127.0.0.1:8090
