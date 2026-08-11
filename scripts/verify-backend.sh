#!/usr/bin/env bash
# Verify all my boss app backend services are healthy (including notification-service)
set -euo pipefail

BASE="${API_BASE:-http://localhost}"
PORTS=(3001 3002 3003 3004 3005 3006)
NAMES=(auth user config squad survey notification)
FAILED=0

for i in "${!PORTS[@]}"; do
  PORT="${PORTS[$i]}"
  NAME="${NAMES[$i]}"
  URL="$BASE:$PORT/api/v1/health"
  if curl -sf "$URL" >/dev/null; then
    echo "OK  $NAME ($URL)"
  else
    echo "FAIL $NAME ($URL)"
    FAILED=1
  fi
done

echo ""
echo "Push / FCM status:"
if curl -sf "$BASE:3006/api/v1/push/status" 2>/dev/null; then
  echo ""
else
  echo "FAIL push/status"
  FAILED=1
fi

echo ""
echo "Auth sign-in smoke test:"
curl -sf -X POST "$BASE:3001/api/v1/auth/sign-in" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}' | head -c 300
echo ""

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
echo "All checks passed."
