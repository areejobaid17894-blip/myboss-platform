#!/usr/bin/env bash
# Smoke-test Orange SSO token using myboss-platform/.env (requires VPN to 10.4.3.27).
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

SSO_URL="${ORANGE_SSO_TOKEN_URL:-http://10.4.3.27:9001/sso/openid-connect/v1/token}"
CLIENT_ID="${ORANGE_SSO_CLIENT_ID:-}"
CLIENT_SECRET="${ORANGE_SSO_CLIENT_SECRET:-}"
SSO_API_KEY="${ORANGE_SSO_API_KEY:-}"

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "ERROR: Set ORANGE_SSO_CLIENT_ID and ORANGE_SSO_CLIENT_SECRET in myboss-platform/.env"
  echo "See docs/deployment/ORANGE_OTP_SETUP.md"
  exit 1
fi

echo "==> Orange OTP SSO smoke test"
echo "    URL: $SSO_URL"
echo "    client_id: $CLIENT_ID"

HEADERS=(-H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json;charset=utf-8")
if [ -n "$SSO_API_KEY" ]; then
  HEADERS+=(-H "apiKey: $SSO_API_KEY")
else
  echo "WARN: ORANGE_SSO_API_KEY not set"
fi

RESP=$(curl -sS --max-time 15 -X POST "$SSO_URL" \
  "${HEADERS[@]}" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" \
  -w "\nHTTP:%{http_code}")

HTTP="${RESP##*HTTP:}"
BODY="${RESP%HTTP:*}"

if [ "$HTTP" != "200" ]; then
  echo "FAIL SSO HTTP $HTTP"
  echo "$BODY"
  exit 1
fi

TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token','')[:20])" 2>/dev/null || echo "")
if [ -z "$TOKEN" ]; then
  echo "FAIL: no access_token in response"
  echo "$BODY"
  exit 1
fi

echo "OK   SSO token received (${TOKEN}…)"
echo ""
echo "Next: set OTP_PROVIDER=orange in .env, redeploy auth-service, then sign-in with a real @orange.com email."
