# myboss-platform

Orchestration layer for **my boss app** — Docker Compose, deploy scripts, and project documentation.

**Client apps use Orange Apigee** for REST APIs. There is **no local nginx API gateway** — backend runs on direct Docker ports locally.

---

## Start here

| Audience | Guide |
|----------|-------|
| **New laptop / phone** | [`docs/NEW_DEVICE_SETUP.md`](docs/NEW_DEVICE_SETUP.md) |
| **DevOps / VM deploy** | [`docs/devops/DEVOPS.md`](docs/devops/DEVOPS.md) |
| **Apigee team** | [`docs/deployment/APIGEE_CONNECTION.md`](docs/deployment/APIGEE_CONNECTION.md) |
| **QA** | [`docs/deployment/TESTING.md`](docs/deployment/TESTING.md) |
| **All docs** | [`docs/README.md`](docs/README.md) |

---

## Layout on your machine

```
myboss-repos/
├── myboss-mobile/      Flutter employee app
├── myboss-admin/       React admin portal
├── myboss-backend/     NestJS microservices
└── myboss-platform/    ← you are here
```

Custom paths:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Docker Desktop | 24+ with Compose v2 |
| Node.js | 20 LTS (admin Vite dev) |
| Flutter | 3.35.7 via FVM (mobile) |

---

## First-time setup

```bash
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Set in `.env`:

```bash
JWT_SECRET=$(openssl rand -base64 48)
INTERNAL_SERVICE_TOKEN=$(openssl rand -base64 32)
DEMO_ADMIN_PASSWORD=admin123
```

Env reference: [`docs/deployment/ENV_AND_GITLAB_VARIABLES.md`](docs/deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## Run the demo locally

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
```

| App | URL |
|-----|-----|
| Admin (Vite — recommended) | `cd ../myboss-admin && npm run dev` → http://127.0.0.1:5173 |
| Admin (Docker) | http://127.0.0.1:8081 |
| Swagger (auth) | http://127.0.0.1:3001/api/v1/docs |
| Apigee APIs | https://api-demo.orange.com |

**Logins:** Admin `admin@orange.com` / `admin123` · Mobile `demo@orange.com` (OTP auto-fills in demo)

```bash
./scripts/reset-demo-data.sh    # before team testing
./scripts/stop-demo-server.sh # stop stack
```

---

## Demo server / VM deploy

```bash
./scripts/install-demo-server.sh /opt/myboss
cd /opt/myboss/myboss-platform
cp .env.example .env
./scripts/deploy-demo-server.sh <SERVER_IP>
```

Wire Apigee proxies to VM `:3001–3006`: [`docs/deployment/APIGEE_CONNECTION.md`](docs/deployment/APIGEE_CONNECTION.md)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh [HOST]` | Backend + admin in Docker |
| `start-demo-server.sh` | Compose up (no extra output) |
| `stop-demo-server.sh` | Stop demo stack |
| `reset-demo-data.sh` | Restore in-memory demo seed |
| `verify-backend.sh` | Health checks :3001–3006 |
| `verify-mobile-api.sh [HOST]` | API governance (direct ports) |
| `verify-mobile-api.sh --apigee` | API governance via Apigee |
| `verify-localhost.sh` | Full feature smoke test |
| `verify-orange-otp.sh` | SSO token smoke test (VPN required) |
| `fix-admin-login.sh` | Recreate auth if admin password fails |
| `install-demo-server.sh [DIR]` | One-time VM Docker setup |

---

## Mobile APK (external testers)

```bash
cd ../myboss-mobile
./build-apigee-android.sh
# → build/android-dist/myboss-apigee-api-demo.orange.com.apk
```

Same Wi‑Fi LAN testing: `./build-local-android.sh`

---

## Local configuration

| File | How |
|------|-----|
| `.env` | `cp .env.example .env` |
| `secrets/fcm-service-account.json` | Firebase Console — never commit |

Push: [`docs/PUSH_FIREBASE_SETUP.md`](docs/PUSH_FIREBASE_SETUP.md)

---

*Orange — my boss app*
