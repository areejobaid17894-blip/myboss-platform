#!/usr/bin/env bash
# Verify API gateway routes on :8090 (local or tunnel URL).
set -euo pipefail

BASE="${1:-http://127.0.0.1:8090}"
RESOLVE=()
if [[ "$BASE" == https://* ]]; then
  HOST="${BASE#https://}"
  IP="$(dig +short @8.8.8.8 "$HOST" | head -1)"
  if [ -n "$IP" ]; then
    RESOLVE=(--resolve "${HOST}:443:${IP}")
  fi
fi

check() {
  local name="$1" url="$2" expect="${3:-200}"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' ${RESOLVE+"${RESOLVE[@]}"} --max-time 20 "$url" || echo 000)"
  if [ "$code" = "$expect" ]; then
    echo "OK   $name ($code)"
  else
    echo "FAIL $name ($code, expected $expect) — $url"
    return 1
  fi
}

echo "Gateway base: $BASE"
check health "$BASE/health"
check auth "$BASE/auth/api/v1/health"
check user "$BASE/user/api/v1/health"
check config "$BASE/config/api/v1/health"
check squad "$BASE/squad/api/v1/health"
check survey "$BASE/survey/api/v1/health"
echo "All gateway routes OK."
