# myboss-platform

DevOps, documentation, and full-stack orchestration for **my boss app**.

## Sibling repositories

Clone all four repos **side by side**:

```
myboss-repos/
├── myboss-mobile/      ← Flutter app
├── myboss-admin/       ← React admin
├── myboss-backend/     ← NestJS services
└── myboss-platform/    ← this repo (docs + deploy)
```

Override paths if needed:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

## Quick start (full demo)

```bash
cp .env.example .env
# Edit JWT_SECRET, INTERNAL_SERVICE_TOKEN

./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

| URL | |
|-----|--|
| Mobile web | http://127.0.0.1:8090/app/ |
| Admin | http://127.0.0.1:8090/login |

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh` | Build backend + admin (Docker) |
| `deploy-mobile-web.sh` | Build mobile web + nginx gateway :8090 |
| `reset-demo-data.sh` | Restore in-memory demo seed |
| `start-demo-tunnel.sh` | Cloudflare public URL |
| `verify-backend.sh` | Health checks |

## Documentation

See [`docs/README.md`](docs/README.md) for the full documentation index.

## GitLab CI

Add `.gitlab-ci.yml` in each app repo; this platform repo can hold deploy pipelines that trigger child projects or build from sibling checkouts.
