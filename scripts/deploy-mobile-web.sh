#!/usr/bin/env bash
set -euo pipefail
if [ "${ALLOW_DEPLOY:-}" != "1" ]; then
  echo "Use: ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh"
  exit 1
fi
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE_DIR="${MYBOSS_MOBILE_DIR:-$PLATFORM_DIR/../myboss-mobile}"
WEB_BUILD="$MOBILE_DIR/build/web"
GATEWAY_CONF="$PLATFORM_DIR/docker/nginx-api-gateway.conf"
GATEWAY_NAME="myboss-api-gateway"

cd "$MOBILE_DIR"
chmod +x build-demo-web.sh
./build-demo-web.sh

NETWORK="$(docker inspect myboss-auth --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || docker network ls --format '{{.Name}}' | grep docker_default | head -1)"
docker stop "$GATEWAY_NAME" 2>/dev/null || true
docker rm "$GATEWAY_NAME" 2>/dev/null || true
docker run -d --name "$GATEWAY_NAME" --network "$NETWORK" \
  -p 8090:8090 \
  -v "$WEB_BUILD:/usr/share/nginx/html/app:ro" \
  -v "$GATEWAY_CONF:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.27-alpine

echo "Mobile web: http://127.0.0.1:8090/app/"
