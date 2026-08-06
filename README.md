# myboss-platform

Orchestration layer for **my boss app** — Docker Compose, nginx demo gateway, deploy scripts, and project documentation.

This project does not contain application source. The Flutter mobile app, React admin, and NestJS backend live as sibling folders next to this one. Platform scripts know how to find them and wire everything together on port **8090**.

---

## What lives here

| Area | Purpose |
|------|---------|
| `scripts/` | Deploy, verify, reset demo data, Cloudflare tunnel |
| `docker/` | Compose stack, nginx gateway config, Postgres |
| `docs/` | Architecture, DevOps, API notes, team guides |

---

## Layout on your machine

Keep all four projects side by side:

```
myboss-repos/
├── myboss-mobile/      Flutter employee app
├── myboss-admin/       React admin portal
├── myboss-backend/     NestJS microservices
└── myboss-platform/    ← you are here
```

If your folders are elsewhere, point scripts at them:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Docker Desktop | 24+ with Compose v2 | Required for the full demo stack |
| Node.js | 20 LTS | Optional — local backend dev without Docker |
| Flutter | 3.35.7 | Mobile web and APK builds (see `myboss-mobile`) |
| cloudflared | Latest | Optional — public demo URL for remote testers |

---

## First-time setup

```bash
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Generate secrets and add them to `.env`:

```bash
JWT_SECRET=$(openssl rand -base64 48)
INTERNAL_SERVICE_TOKEN=$(openssl rand -base64 32)
DEMO_ADMIN_PASSWORD=admin123
```

Optional: `DEMO_HOST`, `TAWK_PROPERTY_ID`.

**New machine?** Follow [`docs/MULTI_REPO_SETUP.md`](docs/MULTI_REPO_SETUP.md#new-machine-checklist).

---

## Run the full demo locally

This is the fastest way to see everything working — backend, admin, and mobile web behind a single gateway.

**1. Start backend and admin (Docker)**

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
```

Brings up six NestJS services (3001–3006) and the admin container (8081). First build takes ~30 seconds.

**2. Build mobile web and start the gateway**

```bash
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

Compiles Flutter web from `../myboss-mobile` and serves it through nginx on **8090**.

**3. Smoke test**

```bash
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

| URL | What |
|-----|------|
| http://127.0.0.1:8090/app/ | Mobile web |
| http://127.0.0.1:8090/login | Admin console |
| http://127.0.0.1:8090/health | Gateway health |
| http://127.0.0.1:8090/auth/api/v1/docs | Swagger (auth) |
| http://127.0.0.1:8090/notification/api/v1/push/status | FCM status (dry-run vs live) |

**Demo logins:** Admin `admin@orange.com` / `admin123` · Mobile `demo@orange.com` (OTP auto-fills in demo mode). Mobile users must accept Terms & Conditions after OTP.

**Reset seed data** before a team session:

```bash
./scripts/reset-demo-data.sh
```

**Stop everything:**

```bash
./scripts/stop-demo-server.sh
docker stop myboss-api-gateway 2>/dev/null || true
```

---

## Demo server / VM deploy

**One-time server prep** (Ubuntu 22.04+, Docker installed):

```bash
./scripts/install-demo-server.sh /opt/myboss
```

This places all four projects under `/opt/myboss/` as siblings.

**Deploy:**

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
# Set JWT_SECRET, INTERNAL_SERVICE_TOKEN, DEMO_HOST=<public-ip>

./scripts/deploy-demo-server.sh <SERVER_IP>
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh <SERVER_IP> --gateway
```

---

## Public URL for remote testers

With the gateway running on :8090:

```bash
./scripts/start-demo-tunnel.sh
```

The tunnel URL is written to `demo-public-url.txt`. Share:

- Mobile: `https://<url>/app/`
- Admin: `https://<url>/login`

Quick tunnels die when `cloudflared` stops — keep the process running and your Mac awake. If testers see **Error 1033**, restart the script and share the **new** URL. Details: [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md)

---

## Demo vs production gateway

| | Demo (today) | Production (target) |
|---|--------------|---------------------|
| API gateway | nginx on `:8090` | Orange **Apigee** |
| API paths | `/auth/api/v1`, `/user/api/v1`, … | Same paths |
| Microservices | Docker `:3001–3006` | Internal only, behind Apigee |

nginx mirrors Apigee routing so mobile and admin can be tested before Apigee is wired up. Production does **not** use nginx as the public gateway.

→ [`docs/architecture/APIGEE_VS_NGINX.md`](docs/architecture/APIGEE_VS_NGINX.md)

---

## External Android APK

For testers on mobile data (outside your Wi‑Fi):

```bash
# 1. Tunnel running (see above)
# 2. From myboss-mobile:
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk
```

→ [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh [HOST]` | Backend + admin in Docker |
| `deploy-mobile-web.sh` | Mobile web build + nginx gateway :8090 |
| `reset-demo-data.sh` | Restore in-memory demo seed |
| `start-demo-tunnel.sh` | Cloudflare public URL |
| `stop-demo-server.sh` | Stop Docker demo stack |
| `verify-backend.sh` | Health checks :3001–3006 + push status |
| `verify-mobile-api.sh` | Gateway + mobile API smoke test |
| `fix-admin-login.sh` | Recreate auth if admin password fails |
| `install-demo-server.sh [DIR]` | One-time Docker setup on a VM |

Only `deploy-mobile-web.sh` requires `ALLOW_DEPLOY=1`.

---

## Local configuration

These files are created on your machine — copy from the `.example` templates where noted.

| File | When you need it | How |
|------|------------------|-----|
| `.env` | Always (Docker deploy) | `cp .env.example .env` |
| `demo-public-url.txt` | Public tunnel demos | `./scripts/start-demo-tunnel.sh` |
| `demo-tunnel.log` | Auto | Written by tunnel script |
| `docker/data/` | Auto | Postgres volume when Docker runs |
| `secrets/fcm-service-account.json` | Push notifications | Download from Firebase Console — never commit |

**Push notifications:** See [`docs/PUSH_FIREBASE_SETUP.md`](docs/PUSH_FIREBASE_SETUP.md).

---

## Documentation

| Topic | Path |
|-------|------|
| Full stack setup (all four projects) | [`docs/MULTI_REPO_SETUP.md`](docs/MULTI_REPO_SETUP.md) |
| Docs index | [`docs/README.md`](docs/README.md) |
| Apigee vs nginx | [`docs/architecture/APIGEE_VS_NGINX.md`](docs/architecture/APIGEE_VS_NGINX.md) |
| Tunnel, Error 1033, external APK | [`docs/deployment/DEMO_TUNNEL_AND_APK.md`](docs/deployment/DEMO_TUNNEL_AND_APK.md) |
| Push notifications (Firebase) | [`docs/PUSH_FIREBASE_SETUP.md`](docs/PUSH_FIREBASE_SETUP.md) |
| DevOps / production deploy | [`docs/devops/DEVOPS.md`](docs/devops/DEVOPS.md) |
| Environment setup | [`docs/deployment/ENVIRONMENT_SETUP.md`](docs/deployment/ENVIRONMENT_SETUP.md) |
| Database & demo seed | [`docs/database/DATABASE.md`](docs/database/DATABASE.md) |
| Team handoff | [`docs/TEAM_REVIEW_GUIDE.md`](docs/TEAM_REVIEW_GUIDE.md) |
