# Preprod connection matrices

**Stage:** preprod only (`APP_ENV=preprod`)  
**Do not use this file for production or development.**  
**Runtime:** two K8s containers — API (`myboss-backend`, `APP_PORT=80`) and admin (`myboss-admin`, `APP_PORT=80`).  
**No localhost / 127.0.0.1. Do not set GitLab `PORT`.**

Replace `TODO_PREPROD_API_PUBLIC_URL` and `TODO_PREPROD_ADMIN_PUBLIC_URL` after ingress exists.

**Hosts on the API pod (required):**

```
10.1.112.95  preprod-notification.xyz.jt.jtgroup
```

---

## Matrix 1 — Preprod: API pod outbound (firewall)

| Source | Destination | Host | Port | Protocol | Purpose | Required |
|--------|-------------|------|------|----------|---------|----------|
| API pod | Preprod MySQL | `10.1.169.88` | `3308` | TCP | Schema `my_boss_pre`, user `my_boss_app_pre` | **Yes** |
| API pod | Preprod SSO (Maxit) | `10.1.112.95` | `9001` | HTTP | OTP — `POST .../sso/openid-connect/v1/token` | **Yes** |
| API pod | Preprod email (Maxit) | `preprod-notification.xyz.jt.jtgroup` | `80` | HTTP | OTP — `POST /email/send` to login email | **Yes** |
| API pod | Firebase FCM | `fcm.googleapis.com` | `443` | HTTPS | Push | Only if `FCM_ENABLED=true` (currently **false**) |
| API pod | Tawk.to | `*.tawk.to` | `443` | HTTPS | Chat widget config | Only if `CHAT_ENABLED=true` |

---

## Matrix 2 — Preprod: inbound to cluster (ingress)

| Source | Target | URL / path | Port | Protocol | Purpose | Required |
|--------|--------|------------|------|----------|---------|----------|
| Employee mobile | API ingress | `TODO_PREPROD_API_PUBLIC_URL` → `/api/v1/*` | `443` | HTTPS | Auth, squads, surveys | **Yes** (after ingress) |
| Admin browser | Admin ingress | `TODO_PREPROD_ADMIN_PUBLIC_URL` | `443` | HTTPS | Admin SPA | **Yes** (after ingress) |
| Admin browser | API ingress | `TODO_PREPROD_API_PUBLIC_URL` → `/api/v1/*` | `443` | HTTPS | Admin REST (JWT). Must be in `CORS_ALLOWED_ORIGINS` | **Yes** (after ingress) |
| K8s probes | API Service | `/api/v1/health` | `80` | HTTP | Liveness / readiness | **Yes** |
| K8s probes | Admin Service | `/health` | `80` | HTTP | Liveness / readiness | **Yes** |

GitLab after ingress: admin `VITE_API_URL=<API public URL>/api/v1` · API `CORS_ALLOWED_ORIGINS=<admin public URL>`.

---

## Matrix 3 — Preprod: inside the cluster

| From | To | Address | Port | Purpose |
|------|-----|---------|------|---------|
| API container | Listens | K8s `APP_PORT` | `80` | NestJS API. Do not set GitLab `PORT`. |
| Admin container | Listens | K8s `APP_PORT` | `80` | SPA + `/runtime-config.js`. Do not set GitLab `PORT`. |
| API process | API process | Do not set `API_INTERNAL_URL` (optional K8s DNS `http://<api-service>:80/api/v1`) | `80` | In-process / Service DNS. No localhost. |
| Admin pod | API | **Not** cluster DNS | — | Browser calls public `VITE_API_URL`. Admin pod does not proxy the API. |

---

## Matrix 4 — Preprod: OTP (login)

| Step | From | To | Host:port | Body | Required |
|------|------|-----|-----------|------|----------|
| 1 | User | Admin or mobile | Public ingress | Email + password (admin) or email (employee) | **Yes** |
| 2 | Client | API via ingress/Apigee | `TODO_PREPROD_API_PUBLIC_URL/api/v1/auth/*` | JSON only | **Yes** |
| 3 | API pod | SSO | `10.1.112.95:9001` | Client credentials | **Yes** |
| 4 | API pod | Email API | `preprod-notification.xyz.jt.jtgroup:80` | OTP email to **login address** | **Yes** |
| 5 | User mailbox | User | Corporate mail | 6-digit OTP | **Yes** |
| 6 | Client | API | `/api/v1/auth/verify-2fa` | `sessionId` + `code` | **Yes** |

OTP is not sent to a redirect/test mailbox.

---

## Matrix 5 — Preprod: Apigee (JSON APIs only)

| From | To | What travels | Image / file body |
|------|-----|--------------|-------------------|
| Mobile / admin | Apigee → API | JSON: auth, squads, surveys, gallery **control** (JWT) | **No** |
| API | Apigee → client | JSON responses, JWT | **No** |

Apigee does **not** carry gallery image bytes (payload limits). Binaries (when gallery is enabled later) go client → Firebase Storage with a short-lived signed URL.

---

## Matrix 6 — Preprod: clients (who talks to whom)

| Client | Calls | Does not call |
|--------|-------|----------------|
| Admin browser | Admin public URL (SPA). API public URL `/api/v1` (JWT). | MySQL, SSO, email API, pod IP |
| Employee mobile | API public URL `/api/v1` (JWT). | Admin SPA, MySQL, SSO, email API |
| API pod | MySQL `10.1.169.88:3308`, SSO `10.1.112.95:9001`, email hostname `:80` | Browser, mobile directly |

---

## Matrix 7 — Preprod: DNS / hosts

| Name | Resolves to | Used by | Required |
|------|-------------|---------|----------|
| `preprod-notification.xyz.jt.jtgroup` | `10.1.112.95` | API pod only (hosts/CoreDNS) | **Yes** |
| `TODO_PREPROD_API_PUBLIC_URL` | API ingress | Mobile + admin browser | **Yes** after ingress |
| `TODO_PREPROD_ADMIN_PUBLIC_URL` | Admin ingress | Admin browser + `CORS_ALLOWED_ORIGINS` | **Yes** after ingress |

---

## Matrix 8 — Preprod: health checks

| Component | Method | Path | Port | Expected |
|-----------|--------|------|------|----------|
| API | GET | `/api/v1/health` | Service `80` or ingress `443` | HTTP 200 |
| Admin | GET | `/health` | Service `80` or ingress `443` | HTTP 200 |

Swagger is off (`SWAGGER_ENABLED=false`).

---

## Matrix 9 — Preprod: not used

| System | Status |
|--------|--------|
| Redis | Not used |
| MySQL in the cluster | Not used — corporate `10.1.169.88:3308` only |
| Production Maxit `10.4.3.27` | Not used in preprod |
| Production MySQL `10.1.165.105` | Not used in preprod |
| GitLab `PORT=3001` | Not used — K8s `APP_PORT=80` |
| `API_INTERNAL_URL` localhost | Not used |
| Gallery upload | Disabled in API until signed-URL design is built |
| FCM / Firebase Storage (gallery) | `FCM_ENABLED=false`; gallery files not in preprod yet |

---

## Matrix 10 — Preprod: future gallery (not open now)

Do **not** open these until Security signs off and upload is re-enabled.

| From | To | Port | Through Apigee? | Purpose |
|------|-----|------|-----------------|---------|
| Client | API (JSON) | `443` | **Yes** | JWT → signed PUT/GET URL |
| Client | Firebase Storage | `443` | **No** | Image bytes only |
| API pod | `storage.googleapis.com` / Firebase | `443` | No | Mint signed URLs (server) |
| API pod | `fcm.googleapis.com` | `443` | No | Push, if FCM enabled later |
