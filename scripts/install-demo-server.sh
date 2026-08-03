#!/usr/bin/env bash
# my boss app — Demo server Docker setup (Ubuntu 22.04+)
set -euo pipefail

echo "==> my boss app — Docker demo setup"

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
  echo "Log out and back in so Docker group applies, then re-run this script."
fi

REPO_DIR="${REPO_DIR:-/opt/myboss/my_boss_v5}"
if [ ! -f "$REPO_DIR/infrastructure/docker/docker-compose.demo.yml" ]; then
  echo "ERROR: Repo not found at $REPO_DIR"
  exit 1
fi

if [ ! -f "$REPO_DIR/.env" ]; then
  cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
  echo "Created .env — set JWT_SECRET and TAWK_PROPERTY_ID before go-live."
fi

echo "Docker: $(docker --version)"
echo "==> Ready. Run: ./infrastructure/scripts/start-demo-server.sh"
