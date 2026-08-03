#!/usr/bin/env bash
# Stop my boss app demo Docker stack
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

COMPOSE_FILE="infrastructure/docker/docker-compose.demo.yml"

docker compose -f "$COMPOSE_FILE" --profile with-admin down
echo "Demo stack stopped."
