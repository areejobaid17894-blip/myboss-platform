#!/usr/bin/env bash
# Verify all my boss app features on localhost (your machine).
# Does NOT touch the Cloudflare tunnel — team keeps using the live URL.
#
# Usage:
#   ./infrastructure/scripts/verify-localhost.sh
#   ./infrastructure/scripts/verify-localhost.sh --quick   # skip chat/survey smoke
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

QUICK=false
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=true ;;
  esac
done

GATEWAY="${LOCAL_GATEWAY:-http://127.0.0.1:8090}"
ADMIN="${LOCAL_ADMIN:-http://127.0.0.1:8081}"
FAILED=0

pass() { echo "  OK   $1"; }
fail() { echo "  FAIL $1"; FAILED=1; }

check_http() {
  local label="$1" url="$2" expected="${3:-200}"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null || echo 000)"
  if [ "$code" = "$expected" ]; then
    pass "$label ($code)"
  else
    fail "$label expected HTTP $expected got $code — $url"
  fi
}

echo "=========================================="
echo " LOCALHOST VERIFICATION"
echo " Gateway: $GATEWAY"
echo "=========================================="
echo ""

echo "==> Infrastructure"
check_http "API gateway health" "$GATEWAY/health"
check_http "Mobile web /app/" "$GATEWAY/app/"
check_http "Admin portal login" "$ADMIN/login"

PORTS=(3001 3002 3003 3004 3005)
NAMES=(auth user config squad survey)
for i in "${!PORTS[@]}"; do
  check_http "${NAMES[$i]}-service direct" "http://127.0.0.1:${PORTS[$i]}/api/v1/health"
done

echo ""
echo "==> Auth (demo@orange.com)"
SIGN=$(curl -sf --max-time 15 -X POST "$GATEWAY/auth/api/v1/auth/sign-in" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}' 2>/dev/null || echo "")
if [ -z "$SIGN" ]; then
  fail "sign-in"
else
  pass "sign-in"
fi

SESSION=$(echo "$SIGN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sessionId',''))" 2>/dev/null || echo "")
OTP=$(echo "$SIGN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('demoOtpCode',''))" 2>/dev/null || echo "")

VERIFY=$(curl -sf --max-time 15 -X POST "$GATEWAY/auth/api/v1/auth/verify-2fa" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\":\"$SESSION\",\"code\":\"$OTP\"}" 2>/dev/null || echo "")
TOKEN=$(echo "$VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('accessToken',''))" 2>/dev/null || echo "")

if [ -n "$TOKEN" ]; then
  pass "verify-2fa (JWT issued)"
else
  fail "verify-2fa — rebuild auth: docker compose -f infrastructure/docker/docker-compose.demo.yml up -d --build auth-service"
fi

echo ""
echo "==> Squad (JWT required)"
USER_ID=$(echo "$VERIFY" | python3 -c "import sys,json; d=json.load(sys.stdin); print((d.get('user') or {}).get('id',''))" 2>/dev/null || echo "4")
AUTH="Authorization: Bearer $TOKEN"
SQUAD=$(curl -sf --max-time 10 -H "$AUTH" "$GATEWAY/squad/api/v1/squads/my/$USER_ID" 2>/dev/null || echo "")
if echo "$SQUAD" | grep -q 'Orange Amman Squad'; then
  pass "demo user in Orange Amman Squad"
else
  fail "demo squad missing — $SQUAD"
fi

NO_SQUAD=$(curl -sf --max-time 10 -H "$AUTH" "$GATEWAY/squad/api/v1/squads/my/2" 2>/dev/null || echo "")
if [ -z "$NO_SQUAD" ] || [ "$NO_SQUAD" = "null" ]; then
  pass "omar.t@orange.com has no squad (gating test account)"
else
  fail "omar should have no squad for gating tests — restart squad-service or redeploy demo"
fi

OMAR_SIGN=$(curl -sf --max-time 15 -X POST "$GATEWAY/auth/api/v1/auth/sign-in" \
  -H "Content-Type: application/json" \
  -d '{"email":"omar.t@orange.com"}' 2>/dev/null || echo "")
OMAR_SESSION=$(echo "$OMAR_SIGN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sessionId',''))" 2>/dev/null || echo "")
OMAR_OTP=$(echo "$OMAR_SIGN" | python3 -c "import sys,json; print(json.load(sys.stdin).get('demoOtpCode',''))" 2>/dev/null || echo "")
OMAR_VERIFY=$(curl -sf --max-time 15 -X POST "$GATEWAY/auth/api/v1/auth/verify-2fa" \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\":\"$OMAR_SESSION\",\"code\":\"$OMAR_OTP\"}" 2>/dev/null || echo "")
OMAR_TOKEN=$(echo "$OMAR_VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('accessToken',''))" 2>/dev/null || echo "")

if [ -n "$OMAR_TOKEN" ]; then
  pass "omar sign-in + verify-2fa"
else
  fail "omar auth flow"
fi

OMAR_JOIN=$(curl -sf --max-time 10 -H "Authorization: Bearer $OMAR_TOKEN" \
  "$GATEWAY/squad/api/v1/squads/join-status/2" 2>/dev/null || echo "")
if echo "$OMAR_JOIN" | grep -q '"inSquad":false'; then
  pass "omar join-status confirms no squad"
else
  fail "omar join-status — $OMAR_JOIN"
fi

JOIN=$(curl -sf --max-time 10 -H "$AUTH" "$GATEWAY/squad/api/v1/squads/join-status/$USER_ID" 2>/dev/null || echo "")
if echo "$JOIN" | grep -q '"inSquad":true'; then
  pass "join-status API"
else
  fail "join-status — $JOIN"
fi

SQUAD_LIST=$(curl -sf --max-time 10 -H "Authorization: Bearer $OMAR_TOKEN" \
  "$GATEWAY/squad/api/v1/squads" 2>/dev/null || echo "")
if echo "$SQUAD_LIST" | grep -q 'Orange Amman Squad'; then
  pass "squad browse lists all squads (omar JWT)"
else
  fail "squad browse empty or auth failed — $SQUAD_LIST"
fi

echo ""
echo "==> User profile (JWT required)"
PROFILE=$(curl -sf --max-time 10 -H "$AUTH" "$GATEWAY/user/api/v1/users/$USER_ID" 2>/dev/null || echo "")
if echo "$PROFILE" | grep -q '"onboardingCompleted":true'; then
  pass "demo profile onboarding complete"
else
  fail "demo profile — $PROFILE"
fi

if [ "$QUICK" = true ] || [ -z "$TOKEN" ]; then
  echo ""
  echo "(skipped chat/survey — use full run or fix auth first)"
else
  echo "==> Live chat (native squad messaging)"
  CHAT_CFG=$(curl -sf --max-time 10 "$GATEWAY/config/api/v1/chat/config" 2>/dev/null || echo "")
  if echo "$CHAT_CFG" | grep -q '"provider":"native"'; then
    pass "chat config (native provider)"
  else
    fail "chat config — $CHAT_CFG"
  fi

  SEND=$(curl -sf --max-time 15 -X POST "$GATEWAY/config/api/v1/chat/messages" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"recipientId":"support","text":"localhost verify ping"}' 2>/dev/null || echo "")
  if echo "$SEND" | grep -q '"senderId"'; then
    pass "send chat message"
  else
    fail "send chat — $SEND"
  fi

  sleep 2
  MSGS=$(curl -sf --max-time 10 "$GATEWAY/config/api/v1/chat/messages?peerId=support" \
    -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "")
  if echo "$MSGS" | grep -q '"senderId":"support"'; then
    pass "support auto-reply received"
  else
    fail "chat poll — $MSGS"
  fi

  echo ""
  echo "==> Surveys"
  SURVEY=$(curl -sf --max-time 10 -H "Authorization: Bearer $TOKEN" "$GATEWAY/survey/api/v1/surveys/catalog" 2>/dev/null || echo "")
  if echo "$SURVEY" | grep -q 'segment'; then
    pass "survey catalog (JWT)"
  else
    fail "survey catalog — $SURVEY"
  fi

  ACTIVE=$(curl -sf --max-time 10 -H "Authorization: Bearer $TOKEN" "$GATEWAY/survey/api/v1/surveys/active/consumer" 2>/dev/null || echo "")
  if echo "$ACTIVE" | grep -q '"segment":"consumer"'; then
    pass "consumer survey template (active/consumer)"
  else
    fail "active survey — $ACTIVE"
  fi

  PROGRESS=$(curl -sf --max-time 10 "$GATEWAY/survey/api/v1/responses/progress/squad-demo-amman?target=50" 2>/dev/null || echo "")
  if echo "$PROGRESS" | grep -q 'completed'; then
    pass "squad progress API"
  else
    fail "squad progress — $PROGRESS"
  fi
fi

echo ""
echo "=========================================="
if [ "$FAILED" -eq 0 ]; then
  echo " ALL LOCALHOST CHECKS PASSED"
else
  echo " SOME CHECKS FAILED — fix above, then re-run"
fi
echo "=========================================="
echo ""
echo "Test locally (you):"
echo "  Mobile web:  $GATEWAY/app/"
echo "  Admin:       $GATEWAY/login"
echo "  Swagger:     $GATEWAY/config/api/v1/docs  (Chat tag)"
echo "  Chat doc:    docs/api/CHAT_API.md"
echo ""
echo "  Flutter emulator / desktop:"
echo "    cd apps/mobile"
echo "    flutter run --dart-define=DEMO_MODE=true"
echo ""
echo "  Flutter on physical phone (same Wi‑Fi):"
echo "    flutter run --dart-define=DEMO_MODE=true --dart-define=API_HOST=<your-lan-ip>"
echo ""

LIVE_URL=""
if [ -f "$REPO_DIR/demo-public-url.txt" ] && [ -s "$REPO_DIR/demo-public-url.txt" ]; then
  LIVE_URL="$(tr -d '[:space:]' < "$REPO_DIR/demo-public-url.txt")"
fi
if [ -n "$LIVE_URL" ]; then
  echo "Team live demo (unchanged — share these):"
  echo "  Mobile web:  ${LIVE_URL}/app/"
  echo "  Admin:       ${LIVE_URL}/login"
  echo ""
fi

echo "Logins:"
echo "  Employee: demo@orange.com + OTP (auto-filled in demo mode)"
echo "  No-squad test: omar.t@orange.com + OTP"
echo "=========================================="

exit "$FAILED"
