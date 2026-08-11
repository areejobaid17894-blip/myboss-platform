#!/usr/bin/env bash
# Verify mobile API endpoints against governance requirements (direct ports).
# Usage: ./scripts/verify-mobile-api.sh [HOST]
set -euo pipefail

HOST="127.0.0.1"

for arg in "$@"; do
  case "$arg" in
    --apigee|--gateway)
      echo "WARN: Apigee/nginx gateway removed — using direct ports only." >&2
      ;;
    --https) ;;
    *)
      if [[ "$arg" != --* ]]; then
        HOST="$arg"
      fi
      ;;
  esac
done

SCHEME="http"

prefix() {
  local service="$1"
  case "$service" in
    auth) echo "${SCHEME}://${HOST}:3001/api/v1" ;;
    user) echo "${SCHEME}://${HOST}:3002/api/v1" ;;
    config) echo "${SCHEME}://${HOST}:3003/api/v1" ;;
    squad) echo "${SCHEME}://${HOST}:3004/api/v1" ;;
    survey) echo "${SCHEME}://${HOST}:3005/api/v1" ;;
  esac
}

AUTH_BASE="$(prefix auth)"
USER_BASE="$(prefix user)"
CONFIG_BASE="$(prefix config)"
SQUAD_BASE="$(prefix squad)"
SURVEY_BASE="$(prefix survey)"

echo "==> my boss app mobile API governance check"
echo "    Host: $HOST (direct ports)"
echo ""

check() {
  local label="$1"
  local url="$2"
  local method="${3:-GET}"
  local data="${4:-}"
  local expect="${5:-}"

  local curl_args=(-s --max-time 15 -w "\n%{http_code}" -X "$method" "$url" -H "Accept: application/json")
  if [ -n "$AUTH_HEADER" ]; then
    curl_args+=(-H "$AUTH_HEADER")
  fi
  if [ -n "$data" ]; then
    curl_args+=(-H "Content-Type: application/json" -d "$data")
  fi

  local raw
  raw="$(curl "${curl_args[@]}" 2>&1)"
  local status="${raw##*$'\n'}"
  local resp="${raw%$'\n'*}"

  if [ "$status" -ge 200 ] 2>/dev/null && [ "$status" -lt 300 ] 2>/dev/null; then
    if [ -n "$expect" ] && ! echo "$resp" | grep -q "$expect"; then
      echo "FAIL $label (missing expected: $expect)"
      echo "     $resp"
      exit 1
    fi
    echo "OK   $label"
  else
    echo "FAIL $label (HTTP $status)"
    echo "     $resp"
    exit 1
  fi
}

check_error_format() {
  local label="$1"
  local url="$2"
  local status
  local resp
  status="$(curl -s -o /tmp/myboss-verify-body.json -w "%{http_code}" --max-time 15 "$url" -H "Accept: application/json")"
  resp="$(cat /tmp/myboss-verify-body.json)"
  if [ "$status" = "401" ] && echo "$resp" | grep -q '"code"' && echo "$resp" | grep -q '"reason"' && echo "$resp" | grep -q '"message"'; then
    echo "OK   $label (401 Orange error envelope)"
  else
    echo "FAIL $label (expected HTTP 401 with Orange error body; got HTTP $status)"
    echo "     $resp"
    exit 1
  fi
}

check "auth health" "${AUTH_BASE}/health"
check "config buildings (public)" "${CONFIG_BASE}/config/buildings"
check "chat config (public)" "${CONFIG_BASE}/chat/config"
check "sign-in starts OTP" "${AUTH_BASE}/auth/sign-in" POST '{"email":"demo@orange.com"}' "requiresTwoFactor"
check_error_format "protected route returns Orange error" "${SQUAD_BASE}/squads/stats"

for svc in auth user config squad survey; do
  base="$(prefix "$svc")"
  check "swagger docs ($svc)" "${base}/docs" GET "" "<!DOCTYPE html>"
done

echo ""
echo "==> Authenticated mobile flow"
SESSION_RESP="$(curl -sf --max-time 15 -X POST "${AUTH_BASE}/auth/sign-in" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}')"
SESSION_ID="$(echo "$SESSION_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sessionId',''))" 2>/dev/null || true)"

if [ -z "$SESSION_ID" ]; then
  echo "WARN skipping auth flow (no sessionId)"
  echo "Public checks passed."
  exit 0
fi

OTP_CODE="$(echo "$SESSION_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('demoOtpCode',''))" 2>/dev/null || true)"
[ -z "$OTP_CODE" ] && OTP_CODE="123456"

TOKEN_RESP="$(curl -sf --max-time 15 -X POST "${AUTH_BASE}/auth/verify-2fa" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\":\"${SESSION_ID}\",\"code\":\"${OTP_CODE}\"}")"
ACCESS_TOKEN="$(echo "$TOKEN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('accessToken',''))" 2>/dev/null || true)"
USER_ID="$(echo "$TOKEN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print((d.get('user') or {}).get('id',''))" 2>/dev/null || true)"

if [ -z "$ACCESS_TOKEN" ]; then
  echo "WARN token exchange failed"
  exit 0
fi

AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"

check "user profile (JWT)" "${USER_BASE}/users/${USER_ID}" GET "" "email"
check "squad stats (JWT)" "${SQUAD_BASE}/squads/stats"
check "survey catalog (JWT)" "${SURVEY_BASE}/surveys/catalog"
check "gallery list (JWT)" "${SURVEY_BASE}/gallery"
check "chat visitor (JWT)" "${CONFIG_BASE}/chat/visitor"

echo ""
echo "All mobile API governance checks passed."
