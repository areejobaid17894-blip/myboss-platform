# my boss app — Deployment Guide

> **DevOps (primary):** [`docs/devops/DEVOPS.md`](../devops/DEVOPS.md)  
> **New machine:** [`docs/NEW_DEVICE_SETUP.md`](../NEW_DEVICE_SETUP.md)  
> **Client URLs:** [`deployment/SERVICE_URLS.md`](SERVICE_URLS.md)  
> **Team handoff:** [`docs/TEAM_REVIEW_GUIDE.md`](../TEAM_REVIEW_GUIDE.md)

---

## Guides by topic

| Topic | Document |
|-------|----------|
| VM install & deploy | [`devops/DEVOPS.md`](../devops/DEVOPS.md) |
| Direct port URLs (local + VM) | [`deployment/SERVICE_URLS.md`](SERVICE_URLS.md) |
| Env + GitLab CI/CD variables | [`deployment/ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md) |
| QA smoke tests | [`deployment/TESTING.md`](TESTING.md) |
| Local dev (all apps) | [`deployment/ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) |

---

## Deploy scripts (from `myboss-platform` root)

```bash
chmod +x scripts/*.sh

# Local or VM — pass SERVER_IP so admin is built with correct API host
./scripts/deploy-demo-server.sh <SERVER_IP>

# Verify
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh <SERVER_IP>

# Maintenance
./scripts/reset-demo-data.sh
./scripts/stop-demo-server.sh
```

Docker files: `docker/` — see `docker/README.md`

---

## Environments

| Environment | API access | Backend | Notes |
|-------------|------------|---------|-------|
| Development | `localhost:3001–3006` | Local Docker or npm | Vite admin on `:5173` |
| Demo / LAN | `<SERVER_IP>:3001–3006` | VM or Mac Docker | Set `DEMO_HOST=<SERVER_IP>` |
| Production | Load balancer / TLS in front of ports | Production infra | Manual + approval |

---

## Backend (Docker)

```bash
docker compose -f docker/docker-compose.demo.yml up -d --build
DEMO_HOST=<SERVER_IP> docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

Six services: auth, user, config, squad, survey, notification — ports **3001–3006**.

---

## Admin portal

```bash
cd myboss-admin
npm run dev                 # local Vite → http://127.0.0.1:5173
npm run build               # with .env pointing at SERVER_IP ports
```

Docker (recommended for LAN access):

```bash
DEMO_HOST=<SERVER_IP> docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

Output: `dist/` → nginx in admin container on **8081**.

---

## Mobile app

```bash
cd myboss-mobile

# Same Wi‑Fi / LAN
./build-local-android.sh

# Remote server
SERVER_HOST=<SERVER_IP> ./build-external-android.sh

# Employee web (dev server)
fvm flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8092 \
  --dart-define=API_HOST=<SERVER_IP> --dart-define=ENV=demo --dart-define=DEMO_MODE=true
```

| Define | Purpose |
|--------|---------|
| `API_HOST=<SERVER_IP>` | Direct microservice host |
| `ENV=demo` | Demo environment |
| `DEMO_MODE=true` | Auto-fill OTP in demo |

---

## Secrets

Never commit `.env` or key files. Use GitLab CI/CD variables in pipelines — see [`ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md).

---

## Health checks

```bash
curl http://127.0.0.1:3001/api/v1/health
curl http://<SERVER_IP>:3001/api/v1/health
```

---

## Firewall (VM)

Open **8081** (admin) and **3001–3006** (APIs). Restrict to office/VPN IP range in production.

---

*Orange — my boss app*
