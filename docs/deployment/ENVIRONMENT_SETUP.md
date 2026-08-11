# my boss app — Environment Setup Guide

Local development for all applications. For VM/production deploy use [`../devops/DEVOPS.md`](../devops/DEVOPS.md).

**Start here on a new machine:** [`../NEW_DEVICE_SETUP.md`](../NEW_DEVICE_SETUP.md)  
**All variables + GitLab:** [`ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md)

---

## Repository layout

```
myboss-repos/
├── myboss-mobile/
├── myboss-admin/
├── myboss-backend/
└── myboss-platform/
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 20 LTS |
| Flutter | 3.35.7 (FVM) |
| Docker | 24+ Compose v2 |
| Android Studio | Latest (mobile) |

---

## Environment files

```bash
# Platform (Docker — required)
cd myboss-platform && cp .env.example .env

# Backend (npm dev only)
cd myboss-backend && cp .env.example .env

# Admin (Vite dev)
cd myboss-admin && cp .env.example .env.development
```

Use the **same** `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN` in platform and backend `.env` if you mix Docker and npm.

---

## Full demo stack

```bash
cd myboss-platform
chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

| App | How to open |
|-----|-------------|
| Admin | `cd ../myboss-admin && npm run dev` → http://127.0.0.1:5173 |
| Swagger | http://127.0.0.1:3001/api/v1/docs |
| Mobile | See below |

---

## Per-app development

### Backend

```bash
cd myboss-backend
npm install
npm run build -w @myboss/common
npm run start:dev
```

### Admin

```bash
cd myboss-admin
npm install
npm run dev
```

`.env.development` points at `localhost:3001–3006`.

### Mobile

**Apigee:**

```bash
cd myboss-mobile
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

**Local backend:**

```bash
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

Web: `./run-local-web.sh`

---

## Apigee vs local

| Mode | Admin | Mobile |
|------|-------|--------|
| Local dev | `npm run dev` (:5173) | `ENV=development` |
| Demo deploy | Docker :8081 or `build:apigee` | `build-apigee-android.sh` |
| API base | Apigee or direct ports | Same |

Details: [`APIGEE_CLIENT_URLS.md`](APIGEE_CLIENT_URLS.md) · [`../architecture/APIGEE_VS_NGINX.md`](../architecture/APIGEE_VS_NGINX.md)

---

## Verify setup

```bash
cd myboss-platform
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
./scripts/verify-localhost.sh
```

QA guide: [`TESTING.md`](TESTING.md)

---

*Orange — my boss app*
