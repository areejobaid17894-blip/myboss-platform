# my boss app — Deployment Guide

> **Team handoff:** See [`docs/TEAM_REVIEW_GUIDE.md`](../TEAM_REVIEW_GUIDE.md) for technology versions, server specs, governance, security, and per-team checklists.

## Deployment guides

| Guide | Path |
|-------|------|
| **DevOps (primary)** | [`docs/devops/DEVOPS.md`](../devops/DEVOPS.md) |
| Run demo server | [`docs/deployment/pdf/02_RUN_DEMO_SERVER.md`](pdf/02_RUN_DEMO_SERVER.md) |
| Apigee | [`docs/deployment/pdf/03_APIGEE_CONNECTION.md`](pdf/03_APIGEE_CONNECTION.md) |
| PDF export | [`docs/deployment/pdf/README.md`](pdf/README.md) |

## Deploy scripts (Docker demo server)

From repo root:

```bash
chmod +x infrastructure/scripts/*.sh
./infrastructure/scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./infrastructure/scripts/deploy-mobile-web.sh
./infrastructure/scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./infrastructure/scripts/verify-localhost.sh
./infrastructure/scripts/stop-demo-server.sh
```

**Documentation:** [`docs/api/API_OVERVIEW.md`](api/API_OVERVIEW.md), [`docs/api/CHAT_API.md`](api/CHAT_API.md)

Docker files: `infrastructure/docker/` — see `infrastructure/docker/README.md`

## Overview

The platform deploys three independent applications to four environments:

| Environment | Purpose | Auto-deploy |
|---|---|---|
| Development | Local developer machines | No |
| Demo | Stakeholder demos, integration testing | Yes (on merge to `develop`) |
| UAT | User acceptance testing | Manual |
| Production | Live system | Manual (approval required) |

## Deployment Architecture

```
GitHub Actions CI/CD
        │
        ├── Build & Test (all apps)
        ├── Generate artifacts
        └── Deploy to target environment
                │
        ┌───────▼───────┐
        │ Google Apigee │  (Production routing)
        └───────┬───────┘
                │
    ┌───────────┼───────────┐
    │           │           │
 Auth Svc    User Svc    Config Svc
    │           │           │
    └───────────┼───────────┘
                │
         PostgreSQL / Redis
```

## Backend Deployment

### Docker Images

Each service builds an independent Docker image from **`infrastructure/docker/`**:

```bash
# From repo root — build all demo services
docker compose -f infrastructure/docker/docker-compose.demo.yml up -d --build

# Or build one service
docker build -f infrastructure/docker/Dockerfile.auth -t myboss/auth-service:latest .
docker build -f infrastructure/docker/Dockerfile.user -t myboss/user-service:latest .
docker build -f infrastructure/docker/Dockerfile.config -t myboss/config-service:latest .
docker build -f infrastructure/docker/Dockerfile.squad -t myboss/squad-service:latest .
docker build -f infrastructure/docker/Dockerfile.survey -t myboss/survey-service:latest .
```

### Kubernetes (Production-ready manifests)

Manifests in `infrastructure/kubernetes/`:

```
kubernetes/
├── base/                    # Shared base configs
│   ├── auth-service/
│   ├── user-service/
│   └── config-service/
└── overlays/
    ├── demo/
    ├── uat/
    └── production/
```

Deploy with Kustomize:

```bash
kubectl apply -k infrastructure/kubernetes/overlays/demo
```

## Admin Portal Deployment

Static build deployed to web server or CDN:

```bash
cd apps/admin-portal
npm run build:demo    # or build:uat, build:production
# Output: dist/ → deploy to hosting
```

## Mobile App Deployment

```bash
cd apps/mobile

# Android demo APK (physical device — probes LAN + tunnel at startup)
./build-local-android.sh
# Output: build/android-dist/myboss-demo-<lan-ip>.apk

# iOS demo build (requires Xcode + Apple ID for device install)
./build-demo-ios.sh --ipa

# Mobile web for gateway /app/
./build-demo-web.sh
ALLOW_DEPLOY=1 ../../infrastructure/scripts/deploy-mobile-web.sh
```

Dart defines for demo builds:

| Define | Purpose |
|---|---|
| `DEMO_MODE=true` | Probe gateway hosts at startup |
| `GATEWAY_ORIGIN=http://<host>:8090` | Primary gateway URL |
| `API_HOSTS=host1,host2` | Fallback hosts (LAN + tunnel) |

See [`apps/mobile/README.md`](../../apps/mobile/README.md).

## Environment Variables

Never commit secrets. Use:

| Environment | Secret Management |
|---|---|
| Development | `.env` file (gitignored) |
| Demo | CI/CD secrets / cloud secret manager |
| UAT | Cloud secret manager |
| Production | Cloud secret manager |

## Database Migrations

```bash
cd apps/backend
npm run migration:run -- --env=demo
```

## Health Check Verification

After deployment, verify all services:

```bash
curl https://api-demo.example.com/auth/health
curl https://api-demo.example.com/user/health
curl https://api-demo.example.com/config/health
```

## Rollback

Each deployment creates versioned artifacts. Rollback by redeploying the previous artifact version via CI/CD or Kubernetes rollout:

```bash
kubectl rollout undo deployment/auth-service
```

---

*Specific infrastructure details (cloud provider, registry, hosting) to be configured once company infrastructure is confirmed.*
