# Connection matrix — Kubernetes deployment

**Audience:** DevOps / network / security  
**Runtime:** two containers on K8s — `myboss-api` (`APP_PORT=80`) and `myboss-admin` (`APP_PORT=80`)  
**Last updated:** August 2026

Use this table to open firewall rules and verify connectivity from the cluster to external systems.

---

## 1. Outbound (from cluster → external)

| Source | Destination | Host / URL | Port | Protocol | Purpose | Required |
|--------|-------------|------------|------|----------|---------|----------|
| `myboss-api` pod | Corporate MySQL | `10.1.165.105` | `3308` | TCP | Application data (users, squads, surveys, config) | **Yes** |
| `myboss-api` pod | Orange SSO (Maxit) | `10.4.3.27` | `9001` | HTTP | OTP — obtain OAuth token | **Yes** |
| `myboss-api` pod | Orange Email API (Maxit) | `10.4.3.27` | `9001` | HTTP | OTP — send verification email to **login email** | **Yes** |
| `myboss-api` pod | Firebase FCM | `fcm.googleapis.com` | `443` | HTTPS | Push notifications | Only if `FCM_ENABLED=true` |
| `myboss-api` pod | Tawk.to (chat widget config) | `*.tawk.to` | `443` | HTTPS | Live chat embed | Only if `CHAT_ENABLED=true` |

**Preprod (staging) only** — replace Orange endpoints when `APP_ENV=preprod`:

| Source | Destination | Host / URL | Port | Purpose |
|--------|-------------|------------|------|---------|
| `myboss-api` pod | Preprod SSO | `10.1.112.95` | `9001` | OTP token |
| `myboss-api` pod | Preprod email API | `preprod-notification.xyz.jt.jtgroup` | `80` | OTP email |

Add hosts entry on the node or pod if DNS does not resolve:  
`10.1.112.95 preprod-notification.xyz.jt.jtgroup`

---

## 2. Inbound (clients → cluster)

| Client | Target | Typical path | Port | Purpose |
|--------|--------|--------------|------|---------|
| Employee mobile app (Android) | Public API ingress | `TODO_DEPLOY_API_PUBLIC_URL` → `myboss-api` Service | `443` (TLS) | Auth, squads, surveys, push registration |
| Admin browser | Public admin ingress | `TODO_DEPLOY_ADMIN_PUBLIC_URL` → `myboss-admin` Service | `443` (TLS) | Admin console SPA |
| Admin browser | Public API ingress | Same API URL as mobile | `443` | Admin calls REST API (JWT) |
| DevOps / probes | API health | `/api/v1/health` on API Service | `80` or ingress | Liveness / readiness |
| DevOps / probes | Admin health | `/health` on admin Service | `80` or ingress | Liveness / readiness |

**TODO after deploy:** set GitLab runtime variables `VITE_API_URL` (admin container) and `CORS_ALLOWED_ORIGINS` (API container). Do not rebuild the admin image to change the API URL.

---

## 3. Internal (inside cluster / single pod)

| From | To | Address | Purpose |
|------|-----|---------|---------|
| `myboss-api` process | Same process / K8s Service | Omit `API_INTERNAL_URL` in GitLab, or set K8s Service DNS `http://myboss-backend:80/api/v1` | Internal module HTTP. **Do not set localhost or PORT.** |
| `myboss-admin` pod | Browser only | — | SPA; API URL from GitLab `VITE_API_URL` at runtime (`/runtime-config.js`) |

---

## 4. Not used

| System | Status |
|--------|--------|
| Redis | **Not used** — removed from env templates |
| Local MySQL / MariaDB in cluster | **Not used** — corporate MySQL only |
| Microservice mesh between API modules | **Not used** — single NestJS process |

---

## 5. Docker build (GitLab CI)

If the pipeline fails with `sh: tsc: not found` when building `myboss-backend`:

- **Cause:** `npm install` ran with production-only deps (TypeScript is a devDependency).
- **Fix:** `myboss-backend/docker/Dockerfile` sets `NODE_ENV=development` in the builder stage and runs `npm install --include=dev`.
- **Not a missing file in `.dockerignore`:** `tsconfig.json` and `libs/common/src` must remain in the build context (they are not ignored).

---

## 6. Variable templates

| Stage | GitLab template (source of truth: **myboss-backend**) |
|-------|-----------------|
| Preprod | [`gitlab-preprod.env.example`](gitlab-preprod.env.example) · backend [`docs/gitlab/gitlab-preprod.env.example`](https://github.com/areejobaid17894-blip/myboss-backend/-/blob/dev/docs/gitlab/gitlab-preprod.env.example) |
| Production | [`gitlab-production.env.example`](gitlab-production.env.example) |
| Development | [`gitlab-development.env.example`](gitlab-development.env.example) |
