# my boss app — Deployment Guide

> **DevOps (primary):** [`docs/devops/DEVOPS.md`](../devops/DEVOPS.md)  
> **New machine:** [`docs/NEW_DEVICE_SETUP.md`](../NEW_DEVICE_SETUP.md)  
> **Team handoff:** [`docs/TEAM_REVIEW_GUIDE.md`](../TEAM_REVIEW_GUIDE.md)

---

## Guides by topic

| Topic | Document |
|-------|----------|
| VM install & deploy | [`devops/DEVOPS.md`](../devops/DEVOPS.md) |
| Apigee proxy wiring | [`deployment/APIGEE_CONNECTION.md`](APIGEE_CONNECTION.md) |
| Client API URLs | [`deployment/APIGEE_CLIENT_URLS.md`](APIGEE_CLIENT_URLS.md) |
| Env + GitLab CI/CD variables | [`deployment/ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md) |
| QA smoke tests | [`deployment/TESTING.md`](TESTING.md) |
| Local dev (all apps) | [`deployment/ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) |

---

## Deploy scripts (from `myboss-platform` root)

```bash
chmod +x scripts/*.sh

# Local or VM
./scripts/deploy-demo-server.sh 127.0.0.1

# Verify
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
./scripts/verify-mobile-api.sh --apigee

# Maintenance
./scripts/reset-demo-data.sh
./scripts/stop-demo-server.sh
```

Docker files: `docker/` — see `docker/README.md`

---

## Environments

| Environment | API gateway | Backend | Auto-deploy |
|-------------|-------------|---------|-------------|
| Development | Direct ports `:3001–3006` | Local Docker or npm | No |
| Demo | `https://api-demo.orange.com` | VM Docker | On merge (planned) |
| UAT | Apigee UAT host | Staging infra | Manual |
| Production | `https://api.orange.com` | Production infra | Manual + approval |

---

## Backend (Docker)

```bash
docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

Six services: auth, user, config, squad, survey, notification — ports 3001–3006.

---

## Admin portal

```bash
cd myboss-admin
npm run build:apigee      # demo — https://api-demo.orange.com
npm run build:production  # production CDN
```

Output: `dist/` → CDN or Docker admin container (8081).

---

## Mobile app

```bash
cd myboss-mobile

# Apigee demo APK (recommended)
./build-apigee-android.sh

# Same Wi‑Fi LAN testing
./build-local-android.sh

# iOS
./build-ios-demo.sh
```

| Define | Purpose |
|--------|---------|
| `GATEWAY_ORIGIN=https://api-demo.orange.com` | Apigee demo |
| `ENV=development` | Direct local ports |
| `DEMO_MODE=true` | Auto-fill OTP in demo |

---

## Secrets

Never commit `.env` or key files. Use GitLab CI/CD variables in pipelines — see [`ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md).

---

## Health checks

```bash
# Local
curl http://127.0.0.1:3001/api/v1/health

# Apigee
curl https://api-demo.orange.com/auth/api/v1/health
```

---

*Orange — my boss app*
