# myboss-platform

DevOps, documentation, and full-stack orchestration for **my boss app**.

This repo does **not** contain application source code. It holds deploy scripts, Docker Compose, nginx gateway config, and all project documentation. Application code lives in sibling repos.

---

## Sibling repositories (required)

Clone all four repos **side by side**:

```
myboss-repos/
├── myboss-mobile/      ← Flutter app
├── myboss-admin/       ← React admin
├── myboss-backend/     ← NestJS services
└── myboss-platform/    ← this repo
```

Override paths if needed:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **Docker Desktop** | 24+ (Compose v2) | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Node.js** | 20 LTS | For optional local backend dev |
| **Flutter** | 3.35.7 | For mobile web/APK builds — see `myboss-mobile` |
| **cloudflared** | Optional | `brew install cloudflared` — public tunnel |

---

## One-time setup

```bash
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Edit `.env` — **required**:

```bash
JWT_SECRET=$(openssl rand -base64 48)
INTERNAL_SERVICE_TOKEN=$(openssl rand -base64 32)
```

Optional: `DEMO_HOST`, `TAWK_PROPERTY_ID`, `DEMO_ADMIN_PASSWORD`.

---

## Run locally — full demo (step by step)

### Step 1 — Backend + admin (Docker)

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
```

This builds and starts:
- 5 NestJS services (ports 3001–3005)
- Admin portal container (port 8081)

Wait ~30s on first build, then verify:

```bash
./scripts/verify-backend.sh
```

### Step 2 — Mobile web + API gateway

```bash
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

Builds Flutter web from `../myboss-mobile` and starts nginx gateway on **8090**.

### Step 3 — Smoke test

```bash
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

| URL | |
|-----|--|
| Mobile web | http://127.0.0.1:8090/app/ |
| Admin | http://127.0.0.1:8090/login |
| Health | http://127.0.0.1:8090/health |
| Swagger | http://127.0.0.1:8090/auth/api/v1/docs |

### Step 4 — Reset demo data (before team testing)

```bash
./scripts/reset-demo-data.sh
```

Restores seed users, squads, and terms-not-accepted state.

### Stop

```bash
./scripts/stop-demo-server.sh
docker stop myboss-api-gateway 2>/dev/null || true
```

---

## Deploy live (demo server / VM)

### One-time server install

```bash
# On Ubuntu 22.04+ with Docker
./scripts/install-demo-server.sh /opt/myboss
```

Or manually clone all four repos to `/opt/myboss/` as siblings.

### Deploy

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
nano .env   # JWT_SECRET, INTERNAL_SERVICE_TOKEN, DEMO_HOST=<public-ip>

./scripts/deploy-demo-server.sh <SERVER_IP>
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh <SERVER_IP> --gateway
```

### Public URL (Cloudflare tunnel)

Requires gateway running on :8090:

```bash
./scripts/start-demo-tunnel.sh
```

Output saved to `demo-public-url.txt` (gitignored). Share:
- Mobile: `https://<url>/app/`
- Admin: `https://<url>/login`

Keep tunnel alive — quick tunnels stop when `cloudflared` exits. Logs: `demo-tunnel.log`.

**Error 1033?** Tunnel process died — restart `./scripts/start-demo-tunnel.sh` and use the **new** URL. Full guide: [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md)

---

## Demo vs production (Apigee vs nginx)

| | Demo (today) | Production (target) |
|---|--------------|---------------------|
| **API gateway** | nginx `:8090` on laptop/VM | **Orange Apigee** |
| **API paths** | `/auth/api/v1`, `/user/api/v1`, … | **Same paths** |
| **Microservices** | Docker `:3001–3005` | Internal only behind Apigee |

nginx mimics Apigee path routing so mobile/admin can be tested before Apigee is connected. **Production does not use nginx as the API gateway.**

Read: [`docs/architecture/APIGEE_VS_NGINX.md`](docs/architecture/APIGEE_VS_NGINX.md)

---

## External Android APK

For testers on **mobile data** (outside your laptop Wi‑Fi):

```bash
# 1. Tunnel running (see above)
# 2. From myboss-mobile:
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk (share by email)
```

Details: [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md)

---

## Scripts reference

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh [HOST]` | Build backend + admin (Docker) |
| `deploy-mobile-web.sh` | Build mobile web + nginx gateway :8090 |
| `reset-demo-data.sh` | Restore in-memory demo seed |
| `start-demo-tunnel.sh` | Cloudflare public URL |
| `stop-demo-server.sh` | Stop Docker demo stack |
| `verify-backend.sh` | Health checks :3001–3005 |
| `verify-mobile-api.sh` | Gateway + mobile API smoke test |
| `install-demo-server.sh [DIR]` | One-time Docker setup on VM |

All deploy scripts require `ALLOW_DEPLOY=1` only for `deploy-mobile-web.sh`.

---

## Files NOT in git

| File / folder | Required? | How to obtain |
|---------------|-----------|---------------|
| `.env` | **Yes** | `cp .env.example .env` |
| `demo-public-url.txt` | Tunnel demo | `./scripts/start-demo-tunnel.sh` |
| `demo-tunnel.log` | Auto | Created by tunnel script |
| `demo-tunnel*.pid` | Auto | PID while tunnel runs |
| `docker/data/` | Auto | Docker Postgres volume |
| `*.log` | Auto | Script / tunnel logs |

**In git:** `.env.example`, `demo-public-url.example.txt`

---

## Documentation

| Doc | Path |
|-----|------|
| Index | [`docs/README.md`](docs/README.md) |
| **Apigee vs nginx** | [`docs/architecture/APIGEE_VS_NGINX.md`](docs/architecture/APIGEE_VS_NGINX.md) |
| **Tunnel + Error 1033 + APK** | [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md) |
| DevOps / deploy | [`docs/devops/DEVOPS.md`](docs/devops/DEVOPS.md) |
| Local setup (all apps) | [`docs/deployment/ENVIRONMENT_SETUP.md`](docs/deployment/ENVIRONMENT_SETUP.md) |
| Database & demo seed | [`docs/database/DATABASE.md`](docs/database/DATABASE.md) |
| Team handoff | [`docs/TEAM_REVIEW_GUIDE.md`](docs/TEAM_REVIEW_GUIDE.md) |

---

## GitLab CI

Each app repo has its own `.gitlab-ci.yml`. This platform repo can host deploy pipelines that checkout sibling projects or trigger child pipelines.
