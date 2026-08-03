#!/usr/bin/env bash
# Diagnose why admin works on the server laptop but not on another device.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

detect_lan_ip() {
  ipconfig getifaddr en0 2>/dev/null \
    || ipconfig getifaddr en1 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}' \
    || echo "unknown"
}

LAN_IP="$(detect_lan_ip)"
ADMIN_PORT=8081
GATEWAY_PORT=8090

echo "=========================================="
echo " ADMIN REMOTE ACCESS CHECK"
echo "=========================================="
echo "Server LAN IP:  ${LAN_IP}"
echo "Admin URL:      http://${LAN_IP}:${ADMIN_PORT}"
echo "Admin (alt):    http://${LAN_IP}:${GATEWAY_PORT}/login"
echo "Gateway health: http://${LAN_IP}:${GATEWAY_PORT}/health"
echo ""

if ! curl -sf "http://127.0.0.1:${ADMIN_PORT}/health" >/dev/null 2>&1; then
  echo "FAIL  Admin is not running on this machine."
  echo "      Run: ./infrastructure/scripts/deploy-demo-server.sh ${LAN_IP}"
  exit 1
fi
echo "OK    Admin responds on this laptop (127.0.0.1:${ADMIN_PORT})"

if curl -sf "http://${LAN_IP}:${ADMIN_PORT}/health" >/dev/null 2>&1; then
  echo "OK    Admin responds via LAN IP on this laptop"
else
  echo "WARN  Admin does not respond via LAN IP on this laptop"
fi

if docker ps --format '{{.Ports}}' --filter name=myboss-admin | grep -q '0.0.0.0:8081'; then
  echo "OK    Docker publishes admin on 0.0.0.0:8081 (all interfaces)"
else
  echo "WARN  Docker may not be publishing admin on all interfaces"
  docker ps --filter name=myboss-admin --format 'Ports: {{.Ports}}'
fi

FW_STATE="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | awk '{print $NF}' | tr -d '.' || echo unknown)"
echo "INFO  macOS firewall: ${FW_STATE}"

echo ""
echo "------------------------------------------"
echo " TEST FROM YOUR OTHER DEVICE (phone/tablet)"
echo "------------------------------------------"
echo "1. Connect the device to the SAME Wi‑Fi as this Mac"
echo "2. Open in browser: http://${LAN_IP}:${GATEWAY_PORT}/health"
echo "   Expected: page shows OK"
echo "3. Then open: http://${LAN_IP}:${ADMIN_PORT}"
echo "   Or:        http://${LAN_IP}:${GATEWAY_PORT}/login"
echo ""
echo "If step 2 FAILS (timeout / cannot connect):"
echo "  Your network blocks device-to-device traffic (common on lab/campus Wi‑Fi)."
echo "  Fixes:"
echo "    A) Run a public tunnel on this Mac:"
echo "       ./infrastructure/scripts/start-demo-admin-tunnel.sh"
echo "       Open the https://*.trycloudflare.com URL on any device"
echo "    B) Share internet from this Mac (hotspot), connect the phone to it"
echo "    C) Ask IT to disable Wi‑Fi client isolation for your subnet"
echo ""
echo "If step 2 works but step 3 fails:"
echo "  Hard-refresh the admin page or try a private/incognito window"
echo "  (old cached builds pointed API calls to localhost)"
echo "=========================================="
