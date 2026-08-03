#!/usr/bin/env bash
# Run mobile app locally against Docker backend (ports 3001–3005).
# For browser testing use the built web app instead: http://127.0.0.1:8090/app/
#
# Usage:
#   ./infrastructure/scripts/run-local-flutter.sh              # auto device
#   ./infrastructure/scripts/run-local-flutter.sh macos        # macOS desktop
#   ./infrastructure/scripts/run-local-flutter.sh android      # Android emulator
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR/apps/mobile"

DEVICE="${1:-}"

if ! curl -sf "http://127.0.0.1:3001/api/v1/health" >/dev/null 2>&1; then
  echo "Backend not running. Start with:"
  echo "  ./infrastructure/scripts/deploy-demo-server.sh"
  exit 1
fi

echo "==> Local Flutter (API → localhost:3001–3005, DEMO_MODE on)"
echo "    Web browser testing: http://127.0.0.1:8090/app/"
echo ""

if [ -n "$DEVICE" ]; then
  flutter run -d "$DEVICE" --dart-define=DEMO_MODE=true
else
  flutter run --dart-define=DEMO_MODE=true
fi
