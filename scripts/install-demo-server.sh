#!/usr/bin/env bash
# my boss app — Demo server Docker setup (Ubuntu 22.04+)
# Usage: ./scripts/install-demo-server.sh [/opt/myboss]
set -euo pipefail

INSTALL_DIR="${1:-/opt/myboss}"

echo "==> my boss app — Docker demo setup"

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
  echo "Log out and back in so Docker group applies, then re-run this script."
fi

PLATFORM_DIR="$INSTALL_DIR/myboss-platform"
if [ ! -f "$PLATFORM_DIR/docker/docker-compose.demo.yml" ]; then
  echo "ERROR: myboss-platform not found at $PLATFORM_DIR"
  echo ""
  echo "Clone all four repos as siblings under $INSTALL_DIR:"
  echo "  git clone https://github.com/areejobaid17894-blip/myboss-backend.git"
  echo "  git clone https://github.com/areejobaid17894-blip/myboss-admin.git"
  echo "  git clone https://github.com/areejobaid17894-blip/myboss-mobile.git"
  echo "  git clone https://github.com/areejobaid17894-blip/myboss-platform.git"
  exit 1
fi

if [ ! -f "$PLATFORM_DIR/.env" ]; then
  cp "$PLATFORM_DIR/.env.example" "$PLATFORM_DIR/.env"
  echo "Created $PLATFORM_DIR/.env — set JWT_SECRET and INTERNAL_SERVICE_TOKEN before go-live."
fi

echo "Docker: $(docker --version)"
echo "==> Ready. Run:"
echo "  cd $PLATFORM_DIR"
echo "  ./scripts/deploy-demo-server.sh <SERVER_IP>"
echo "  ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh"
