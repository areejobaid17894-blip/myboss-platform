#!/usr/bin/env bash
# Stop my boss app demo Docker stack
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"

docker compose -f docker/docker-compose.demo.yml --profile with-admin down
docker stop myboss-api-gateway 2>/dev/null || true
docker rm myboss-api-gateway 2>/dev/null || true
echo "Demo stack stopped."
