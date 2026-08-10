#!/usr/bin/env bash
# Proxy VPN-internal Orange APIs on Mac host for Docker auth-service.
# Postman works on Mac+VPN; Docker cannot reach 10.4.3.x directly.
#
# Usage (VPN connected):
#   ./scripts/start-vpn-proxy.sh
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$PLATFORM_DIR/vpn-proxy.log"

screen -S myboss-vpn-proxy -X quit 2>/dev/null || true
pkill -f "scripts/vpn-proxy.py" 2>/dev/null || true
sleep 1

echo "==> Starting VPN proxy (screen: myboss-vpn-proxy)"
echo "    SSO:   host.docker.internal:19001 → 10.4.3.27:9001"
echo "    Email: host.docker.internal:19002 → preprod-notification.xyz.jt.jtgroup:80"
echo "    Log:   $LOG_FILE"
echo ""

: >"$LOG_FILE"
screen -dmS myboss-vpn-proxy bash -c "python3 '$PLATFORM_DIR/scripts/vpn-proxy.py' 2>&1 | tee -a '$LOG_FILE'"

for _ in $(seq 1 15); do
  if lsof -iTCP:19001 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "VPN proxy listening on :19001 and :19002"
    echo ""
    echo "Auth-service URLs (already in .env):"
    echo "  ORANGE_SSO_TOKEN_URL=http://host.docker.internal:19001/sso/openid-connect/v1/token"
    echo "  ORANGE_EMAIL_API_URL=http://host.docker.internal:19002/email/send"
    echo ""
    echo "Stop: screen -S myboss-vpn-proxy -X quit"
    exit 0
  fi
  sleep 1
done

echo "ERROR: VPN proxy did not start. tail -f $LOG_FILE"
exit 1
