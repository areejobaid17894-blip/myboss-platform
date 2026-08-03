#!/usr/bin/env bash
# Restart local backend only (gallery uploads persist until Amman midnight).
# Does NOT rebuild or redeploy the mobile web at /app/.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

echo "==> Rebuilding survey-service (demo gallery persistence)..."
docker compose -f infrastructure/docker/docker-compose.demo.yml up -d --build survey-service

echo ""
echo "Gallery uploads persist in Docker volume 'myboss-demo-gallery' until end of day (Asia/Amman)."
echo "Deployed mobile web at /app/ is unchanged."
