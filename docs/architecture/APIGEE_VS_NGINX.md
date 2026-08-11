# Apigee vs nginx — client API gateway

**Audience:** Mobile, admin, backend, DevOps, Apigee platform teams  
**Purpose:** Client apps use **Orange Apigee**. nginx `:8090` is **local development only**.

---

## Summary

| Layer | Client apps (mobile + admin) | Local full-stack dev |
|-------|------------------------------|----------------------|
| **API gateway** | **Orange Apigee** | nginx on `:8090` (optional) |
| **Demo API base** | `https://api-demo.orange.com` | `http://127.0.0.1:8090` or direct ports |
| **Production API base** | `https://api.orange.com` | — |
| **Microservices** | Internal only (`:3001–3006`) | Docker on `:3001–3006` |
| **API path shape** | `/auth/api/v1`, `/user/api/v1`, … | **Same paths** |

**Client apps must not target nginx or Cloudflare tunnel URLs in new builds.** Use Apigee — see [`../deployment/APIGEE_CLIENT_URLS.md`](../deployment/APIGEE_CLIENT_URLS.md).

---

## Architecture

### Production / shared demo (clients)

```
Mobile app / Admin SPA
        │
        ▼
Orange Apigee  (https://api-demo.orange.com or https://api.orange.com)
        │   TLS, JWT policies, rate limits, CORS
        ├── /auth/api/v1/**         → auth-service
        ├── /user/api/v1/**         → user-service
        ├── /config/api/v1/**       → config-service (+ chat)
        ├── /squad/api/v1/**        → squad-service
        ├── /survey/api/v1/**       → survey-service
        └── /notification/api/v1/** → notification-service
```

### Local development (optional nginx)

```
Developer laptop
        │
        ▼
nginx :8090  ◄── LOCAL ONLY — not for production APK/admin builds
        ├── /app/           → Flutter web static
        ├── /login          → admin UI
        └── /auth|user|…/api/v1 → Docker microservices
```

nginx mirrors Apigee paths so you can test routing locally before Apigee cutover.

---

## Client configuration

| App | Apigee (use this) | Legacy nginx (local only) |
|-----|-------------------|---------------------------|
| **Admin** | `npm run build:apigee` with `VITE_API_GATEWAY_ORIGIN=https://api-demo.orange.com` | `npm run build:local-demo` |
| **Mobile APK** | `./build-apigee-android.sh` or `./build-external-android.sh` | `USE_NGINX_TUNNEL=true ./build-external-android.sh` |
| **Mobile run** | `--dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com` | `--dart-define=GATEWAY_ORIGIN=http://10.0.2.2:8090` |

Full URL table: [`../deployment/APIGEE_CLIENT_URLS.md`](../deployment/APIGEE_CLIENT_URLS.md)

---

## What stays the same

1. Six NestJS microservices — auth, user, config, squad, survey, notification  
2. REST paths — e.g. `POST /auth/api/v1/auth/sign-in`  
3. Orange error envelope — `{ code, reason, message, infoURL? }`  
4. JWT from auth-service; `Authorization: Bearer` on protected routes  

---

## Apigee setup reference

- [`../deployment/pdf/03_APIGEE_CONNECTION.md`](../deployment/pdf/03_APIGEE_CONNECTION.md) — proxy routes for Apigee team  
- [`GOVERNANCE.md`](GOVERNANCE.md) — auth classes and error envelope  

---

## Common misconceptions

| Misconception | Reality |
|---------------|---------|
| “Ship APKs with nginx/tunnel URL” | **No** — use Apigee `https://api-demo.orange.com` |
| “nginx is production gateway” | **No** — local dev stand-in only |
| “Apigee paths differ from demo” | **No** — same `/auth/api/v1`, … prefixes |

---

## Local nginx commands (dev only)

From **`myboss-platform`**:

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

See also: [`../deployment/DEMO_TUNNEL_AND_APK.md`](../deployment/DEMO_TUNNEL_AND_APK.md) (legacy tunnel path)

---

*Orange — my boss app*
