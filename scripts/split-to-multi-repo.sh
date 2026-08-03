#!/usr/bin/env bash
# Split my_boss_v5 monorepo into 4 GitLab-ready repositories (sibling layout).
#
# Output layout (default TARGET_PARENT=~/Desktop/myboss-repos):
#   myboss-mobile/     Flutter app
#   myboss-admin/      React admin portal
#   myboss-backend/    NestJS microservices + docker/
#   myboss-platform/   docs, deploy scripts, docker-compose orchestration
#
# Usage: ./infrastructure/scripts/split-to-multi-repo.sh [TARGET_PARENT]
set -euo pipefail

SOURCE="${SOURCE:-$(cd "$(dirname "$0")/../.." && pwd)}"
TARGET_PARENT="${1:-$HOME/Desktop/myboss-repos}"

MOBILE="$TARGET_PARENT/myboss-mobile"
ADMIN="$TARGET_PARENT/myboss-admin"
BACKEND="$TARGET_PARENT/myboss-backend"
PLATFORM="$TARGET_PARENT/myboss-platform"

RSYNC_EX=(--archive --delete
  --exclude node_modules --exclude build --exclude dist
  --exclude .dart_tool --exclude .gradle-home --exclude .env
  --exclude '.env.*' --exclude '!.env.example'
  --exclude coverage --exclude '*.log' --exclude .DS_Store
  --exclude demo-public-url.txt --exclude '**/tsconfig.tsbuildinfo'
)

echo "==> Source:  $SOURCE"
echo "==> Target:  $TARGET_PARENT"
mkdir -p "$TARGET_PARENT"

echo "==> Copying myboss-mobile..."
mkdir -p "$MOBILE"
rsync "${RSYNC_EX[@]}" "$SOURCE/apps/mobile/" "$MOBILE/"

echo "==> Copying myboss-admin..."
mkdir -p "$ADMIN"
rsync "${RSYNC_EX[@]}" "$SOURCE/apps/admin-portal/" "$ADMIN/"

echo "==> Copying myboss-backend..."
mkdir -p "$BACKEND"
rsync "${RSYNC_EX[@]}" "$SOURCE/apps/backend/" "$BACKEND/"
mkdir -p "$BACKEND/docker"
cp "$SOURCE/infrastructure/docker/Dockerfile.auth" "$BACKEND/docker/"
cp "$SOURCE/infrastructure/docker/Dockerfile.user" "$BACKEND/docker/"
cp "$SOURCE/infrastructure/docker/Dockerfile.config" "$BACKEND/docker/"
cp "$SOURCE/infrastructure/docker/Dockerfile.squad" "$BACKEND/docker/"
cp "$SOURCE/infrastructure/docker/Dockerfile.survey" "$BACKEND/docker/"

echo "==> Copying myboss-platform..."
mkdir -p "$PLATFORM/docs" "$PLATFORM/docker" "$PLATFORM/scripts"
rsync "${RSYNC_EX[@]}" "$SOURCE/docs/" "$PLATFORM/docs/"
rsync "${RSYNC_EX[@]}" "$SOURCE/infrastructure/scripts/" "$PLATFORM/scripts/"
cp "$SOURCE/infrastructure/docker/docker-compose.demo.yml" "$PLATFORM/docker/"
cp "$SOURCE/infrastructure/docker/docker-compose.yml" "$PLATFORM/docker/" 2>/dev/null || true
cp "$SOURCE/infrastructure/docker/nginx-api-gateway.conf" "$PLATFORM/docker/"
cp "$SOURCE/infrastructure/docker/nginx-admin.conf" "$PLATFORM/docker/" 2>/dev/null || true
cp "$SOURCE/.env.example" "$PLATFORM/"
cp "$SOURCE/demo-public-url.example.txt" "$PLATFORM/" 2>/dev/null || true

# --- Fix backend Dockerfiles (monorepo paths → backend repo root) ---
for df in "$BACKEND/docker"/Dockerfile.*; do
  sed -i '' 's|apps/backend/||g' "$df"
done

# --- Admin docker ---
mkdir -p "$ADMIN/docker"
sed 's|apps/admin-portal/||g; s|COPY infrastructure/docker/nginx.conf|COPY docker/nginx.conf|' \
  "$SOURCE/infrastructure/docker/Dockerfile.admin-portal" > "$ADMIN/docker/Dockerfile"
cp "$SOURCE/infrastructure/docker/nginx.conf" "$ADMIN/docker/nginx.conf"

# --- Platform docker-compose (multi-repo build contexts) ---
cat > "$PLATFORM/docker/docker-compose.demo.yml" << 'YAML'
# Demo stack — run from myboss-platform with sibling repos:
#   export MYBOSS_BACKEND_DIR=../myboss-backend
#   export MYBOSS_ADMIN_DIR=../myboss-admin
#   docker compose -f docker/docker-compose.demo.yml up -d --build
#
# Default: expects myboss-backend and myboss-admin as siblings of myboss-platform.

x-backend: &backend_ctx
  context: ${MYBOSS_BACKEND_DIR:-../myboss-backend}

services:
  auth-service:
    build:
      <<: *backend_ctx
      dockerfile: docker/Dockerfile.auth
    container_name: myboss-auth
    restart: unless-stopped
    ports: ['3001:3001']
    env_file: [../.env]
    environment:
      NODE_ENV: demo
      APP_ENV: demo
      INTERNAL_SERVICE_TOKEN: ${INTERNAL_SERVICE_TOKEN:-demo-internal-sync}
      USER_SERVICE_URL: http://user-service:3002/api/v1

  user-service:
    build:
      <<: *backend_ctx
      dockerfile: docker/Dockerfile.user
    container_name: myboss-user
    restart: unless-stopped
    ports: ['3002:3002']
    env_file: [../.env]
    environment:
      NODE_ENV: demo
      APP_ENV: demo
      INTERNAL_SERVICE_TOKEN: ${INTERNAL_SERVICE_TOKEN:-demo-internal-sync}
      CONFIG_SERVICE_URL: http://config-service:3003/api/v1/config/employee-settings

  config-service:
    build:
      <<: *backend_ctx
      dockerfile: docker/Dockerfile.config
    container_name: myboss-config
    restart: unless-stopped
    ports: ['3003:3003']
    env_file: [../.env]
    environment:
      NODE_ENV: demo
      APP_ENV: demo

  squad-service:
    build:
      <<: *backend_ctx
      dockerfile: docker/Dockerfile.squad
    container_name: myboss-squad
    restart: unless-stopped
    ports: ['3004:3004']
    env_file: [../.env]
    environment:
      NODE_ENV: demo
      APP_ENV: demo
      INTERNAL_SERVICE_TOKEN: ${INTERNAL_SERVICE_TOKEN:-demo-internal-sync}
      USER_SERVICE_URL: http://user-service:3002/api/v1
      SURVEY_SERVICE_URL: http://survey-service:3005/api/v1

  survey-service:
    build:
      <<: *backend_ctx
      dockerfile: docker/Dockerfile.survey
    container_name: myboss-survey
    restart: unless-stopped
    ports: ['3005:3005']
    env_file: [../.env]
    environment:
      NODE_ENV: demo
      APP_ENV: demo
      USER_SERVICE_URL: http://user-service:3002/api/v1
      DEMO_GALLERY_FILE: /app/data/demo-gallery.json
      DEMO_GALLERY_TZ: Asia/Amman
    volumes:
      - myboss-demo-gallery:/app/data

  admin-portal:
    build:
      context: ${MYBOSS_ADMIN_DIR:-../myboss-admin}
      dockerfile: docker/Dockerfile
      args:
        BUILD_MODE: local-demo
        DEMO_HOST: ${DEMO_HOST:-localhost}
    container_name: myboss-admin
    restart: unless-stopped
    ports: ['8081:80']
    profiles: [with-admin]

volumes:
  myboss-demo-gallery:
YAML

# Fix env_file path in compose - use platform root .env
sed -i '' 's|env_file: \[../.env\]|env_file: [${PLATFORM_ENV_FILE:-../.env}]|g' "$PLATFORM/docker/docker-compose.demo.yml" 2>/dev/null || true

# Patch platform scripts for multi-repo paths
patch_script() {
  local f="$1"
  [ -f "$f" ] || return 0
  # Replace monorepo REPO_DIR assumption with platform dir + sibling vars
  if ! grep -q 'MYBOSS_BACKEND_DIR' "$f" 2>/dev/null; then
    sed -i '' '1a\
# Multi-repo: set MYBOSS_BACKEND_DIR, MYBOSS_ADMIN_DIR, MYBOSS_MOBILE_DIR if not using default siblings.
' "$f" 2>/dev/null || true
  fi
}

# deploy-demo-server for platform
cat > "$PLATFORM/scripts/deploy-demo-server.sh" << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
export MYBOSS_ADMIN_DIR="${MYBOSS_ADMIN_DIR:-$PLATFORM_DIR/../myboss-admin}"

if [ -n "${1:-}" ]; then export DEMO_HOST="$1"
elif [ -z "${DEMO_HOST:-}" ]; then
  DEMO_HOST="$(curl -fsS --max-time 5 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo localhost)"
  export DEMO_HOST
fi

[ -f .env ] || cp .env.example .env

echo "==> Backend: $MYBOSS_BACKEND_DIR"
echo "==> Admin:   $MYBOSS_ADMIN_DIR"
echo "==> DEMO_HOST: $DEMO_HOST"

docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal

sleep 15
./scripts/verify-backend.sh || true
echo "Demo ready — gateway :8090 (run deploy-mobile-web.sh after backend)"
SCRIPT
chmod +x "$PLATFORM/scripts/deploy-demo-server.sh"

# deploy-mobile-web for platform
cat > "$PLATFORM/scripts/deploy-mobile-web.sh" << 'SCRIPT'
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
SCRIPT
chmod +x "$PLATFORM/scripts/deploy-mobile-web.sh"

# reset-demo-data for platform
cat > "$PLATFORM/scripts/reset-demo-data.sh" << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLATFORM_DIR"
export MYBOSS_BACKEND_DIR="${MYBOSS_BACKEND_DIR:-$PLATFORM_DIR/../myboss-backend}"
docker compose -f docker/docker-compose.demo.yml up -d --build user-service survey-service
docker compose -f docker/docker-compose.demo.yml restart auth-service squad-service
sleep 8
./scripts/verify-backend.sh || true
echo "Demo data reset complete."
SCRIPT
chmod +x "$PLATFORM/scripts/reset-demo-data.sh"

# Root README for split layout
cat > "$TARGET_PARENT/README.md" << EOF
# my boss app — Multi-repo layout

Clone all four repositories as **siblings**:

\`\`\`
myboss-repos/
├── myboss-mobile/      # Flutter employee app
├── myboss-admin/       # React admin portal
├── myboss-backend/     # NestJS microservices
├── myboss-platform/    # Docs, deploy scripts, docker-compose
└── README.md           # this file
\`\`\`

## Quick start

\`\`\`bash
cd myboss-platform
cp .env.example .env
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
\`\`\`

## GitLab

Create 4 empty GitLab projects and push each folder:

\`\`\`bash
cd myboss-backend && git init && git add . && git commit -m "Initial backend split"
cd ../myboss-admin && git init && git add . && git commit -m "Initial admin split"
cd ../myboss-mobile && git init && git add . && git commit -m "Initial mobile split"
cd ../myboss-platform && git init && git add . && git commit -m "Initial platform split"
\`\`\`

Generated from \`my_boss_v5\` on $(date -u +%Y-%m-%d).
EOF

# Per-repo README headers
for repo in mobile admin backend platform; do
  case $repo in
    mobile) d="$MOBILE"; title="myboss-mobile" ;;
    admin) d="$ADMIN"; title="myboss-admin" ;;
    backend) d="$BACKEND"; title="myboss-backend" ;;
    platform) d="$PLATFORM"; title="myboss-platform" ;;
  esac
  if [ -f "$d/README.md" ]; then
    sed -i '' "1i\\
> Part of **my boss** multi-repo. See sibling \`myboss-platform\` for full-stack deploy.\\
\\
" "$d/README.md" 2>/dev/null || true
  fi
done

# Mobile build script deploy hint
sed -i '' 's|../../infrastructure/scripts/deploy-mobile-web.sh|../myboss-platform/scripts/deploy-mobile-web.sh|g' \
  "$MOBILE/build-demo-web.sh" 2>/dev/null || true

echo ""
echo "=========================================="
echo " SPLIT COMPLETE"
echo "=========================================="
echo "  $MOBILE"
echo "  $ADMIN"
echo "  $BACKEND"
echo "  $PLATFORM"
echo ""
echo "Next: cd each repo && git init && git remote add gitlab <url> && git push"
echo "=========================================="
