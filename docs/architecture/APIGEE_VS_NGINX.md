# Apigee vs nginx — demo vs production

**Audience:** Mobile, admin, backend, DevOps, Apigee platform teams  
**Purpose:** Clarify why demo uses nginx on port **8090**, and why production uses **Orange Apigee** instead.

---

## Summary

| Layer | Demo (today) | Production (target) |
|-------|----------------|---------------------|
| **API gateway** | nginx on `:8090` (local/VM) | **Orange Apigee** |
| **Mobile / admin API base** | `http(s)://<host>:8090` or Cloudflare tunnel | `https://api.orange.com` (Apigee) |
| **Microservices** | Docker on `:3001–3005` | Same services, **internal only** |
| **API path shape** | `/auth/api/v1`, `/user/api/v1`, … | **Same paths** behind Apigee |
| **Static UI** | nginx serves `/app/` + proxies admin | CDN / hosting + Apigee for APIs |

**The microservices do not change.** Only the **entry point** in front of them changes: nginx (demo) → Apigee (production).

---

## Architecture comparison

### Demo (development / QA / event)

```
Phone / browser
      │
      ▼
Cloudflare quick tunnel (optional) ──► nginx gateway :8090  ◄── DEMO ONLY
      │                                      │
      │                                      ├── /app/          → Flutter web (static)
      │                                      ├── /login         → admin UI (proxy)
      │                                      ├── /auth/api/v1   → auth-service :3001
      │                                      ├── /user/api/v1   → user-service :3002
      │                                      ├── /config/api/v1 → config-service :3003
      │                                      ├── /squad/api/v1  → squad-service :3004
      │                                      └── /survey/api/v1  → survey-service :3005
      │
      └── Same Wi‑Fi: http://<LAN-IP>:8090 (no tunnel)
```

nginx is a **stand-in for Apigee**. It exposes the **same URL paths** Apigee will use, so mobile and admin can be tested before Apigee is wired.

### Production (target)

```
Phone / browser
      │
      ▼
Orange Apigee  ◄── PRODUCTION API GATEWAY
      │   (TLS, JWT verify, rate limits, CORS, spike arrest)
      │
      ├── /auth/api/v1/**   → auth-service (internal)
      ├── /user/api/v1/**   → user-service (internal)
      ├── /config/api/v1/** → config-service (internal)
      ├── /squad/api/v1/**  → squad-service (internal)
      └── /survey/api/v1/** → survey-service (internal)
```

Ports **3001–3005 are not public** in production. Only Apigee (and ops tooling) reach them.

---

## What nginx does in demo (and Apigee will do in prod)

| Responsibility | Demo (nginx) | Production (Apigee) |
|----------------|--------------|---------------------|
| Single public API hostname | `:8090` or tunnel URL | `https://api-demo.orange.com` |
| Path-based routing to microservices | Yes | Yes |
| TLS termination | Tunnel or none (LAN HTTP) | Apigee |
| JWT validation on protected routes | Backend services | Apigee + backend |
| Rate limiting | No (demo) | Spike arrest / quotas |
| CORS for web admin + mobile | nginx / backend | Apigee policies |
| Serve Flutter web at `/app/` | nginx (static files) | CDN or separate host (not Apigee) |
| Serve admin UI at `/login` | nginx → admin container | CDN or separate host |

**Apigee replaces nginx for API traffic only.** Mobile web and admin SPA may live on CDN or another host; they still call Apigee for REST APIs.

---

## What stays the same when moving to Apigee

1. **Five NestJS microservices** — auth, user, config, squad, survey  
2. **REST paths** — e.g. `POST /auth/api/v1/auth/sign-in`, `GET /user/api/v1/users/:id`  
3. **Orange error envelope** — `{ code, reason, message, infoURL? }`  
4. **JWT** from auth-service; `Authorization: Bearer` on protected routes  
5. **Swagger** at `/api/v1/docs` per service (disabled in prod unless configured)  
6. **Demo seed constants** — `myboss-backend/libs/common/src/demo/demo-seed.constants.ts`

---

## What changes in app configuration

| App | Demo config | Production config |
|-----|-------------|-------------------|
| **Mobile APK** | `--dart-define=API_HOSTS=<tunnel-or-LAN>` | Apigee base URL baked in or from remote config |
| **Mobile web** | Same-origin via gateway `/app/` | Host on CDN; API calls go to Apigee |
| **Admin** | `.env.local-demo` — relative `/auth/api/v1` paths | `.env.production` — full Apigee URLs |
| **Backend `.env`** | `APP_ENV=demo` | `APP_ENV=production`, no public ports |

Example production API base:

```
https://api-demo.orange.com/auth/api/v1/auth/sign-in
https://api-demo.orange.com/user/api/v1/users/4
```

Same paths as demo gateway — only the **host** changes.

---

## Apigee setup reference

Full proxy routes, policies, and public vs internal endpoints:

- [`../deployment/pdf/03_APIGEE_CONNECTION.md`](../deployment/pdf/03_APIGEE_CONNECTION.md)
- [`GOVERNANCE.md`](GOVERNANCE.md) — auth classes and error envelope

---

## Common misconceptions

| Misconception | Reality |
|---------------|---------|
| “We use nginx in production” | **No** — nginx is demo-only. Production uses **Apigee**. |
| “Microservices talk to nginx directly” | Services expose `/api/v1`; nginx/Apigee **proxies** to them. |
| “Splitting repos changed Apigee paths” | **No** — paths are unchanged; only repo layout changed. |
| “Cloudflare tunnel is production” | **No** — quick tunnel is for temporary external demo access only. |

---

## Demo commands (nginx gateway)

From **`myboss-platform`**:

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

See also: [`../deployment/DEMO_TUNNEL_AND_APK.md`](../deployment/DEMO_TUNNEL_AND_APK.md)

---

*Orange — my boss app*
