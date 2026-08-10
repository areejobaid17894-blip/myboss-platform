# Security Guide

**Audience:** Security, compliance, backend, mobile, DevOps  
**Scope:** Authentication, authorization, secrets, API security, and production hardening

Governance (Orange errors, Apigee): [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md)

---

## 1. Security model overview

```
Client (mobile / admin)
    │
    ▼ JWT Bearer (access 15m + refresh 7d)
Apigee / Gateway :8090
    │
    ▼ Global JwtAuthGuard + RolesGuard
Microservices (auth, user, config, squad, survey)
    │
    ▼ Internal sync: X-Internal-Service-Token (service-to-service only)
Cross-service calls (auth→user, squad→user, survey→user profile check)
```

---

## 2. Authentication

### JWT tokens

| Setting | Default | Config |
|---------|---------|--------|
| Access token TTL | 15 minutes | `JWT_EXPIRES_IN` |
| Refresh token TTL | 7 days | `JWT_REFRESH_EXPIRES_IN` |
| Secret | Required | `JWT_SECRET` in `.env` |

**Rules:**
- Boot **fails** if `JWT_SECRET` is default when `APP_ENV ≠ development`
- All routes protected unless `@Public()` on handler/class
- Invalid/expired token → Orange code **41** or **42**

### 2FA (demo)

| Setting | Demo | Production |
|---------|------|------------|
| Provider | In-memory OTP | Email/SMS provider TBD |
| Flag | `TWO_FA_DEMO_ENABLED=true` | Disable demo; wire real provider |
| Mobile | OTP auto-fill when `DEMO_MODE=true` | Never auto-fill |

Endpoint: `POST /auth/api/v1/auth/verify-2fa` (Orange naming — not `verify-otp`).

### Admin sign-in

- Demo credentials gated in admin portal when `VITE_APP_ENV=demo`
- Change `DEMO_ADMIN_PASSWORD` for non-local deploys

---

## 3. Authorization (RBAC)

### Roles

| Role | JWT claim | Capabilities |
|------|-----------|--------------|
| `employee` | `roles: ['employee']` | Mobile app, squad features when `squad_id` set |
| `admin` | `roles: ['admin']` | Admin portal, CRUD, analytics, company/governorate reports |
| `super_admin` | `roles: ['super_admin']` | User delete, elevated admin ops |

Enforced by `@Roles(Role.ADMIN)` + `RolesGuard`. Missing role → Orange code **50** (`FORBIDDEN`).

### Squad membership (additional gate)

Backend validates squad on sensitive endpoints (not just mobile UI):

| Endpoint | Rule |
|----------|------|
| `POST /survey/api/v1/responses` | JWT `sub` = body `userId`; profile `squad_id` = body `squadId` |
| `POST /survey/api/v1/gallery` | Same |
| `GET /survey/api/v1/responses/reports/squad?id=` | Caller must belong to squad |
| `GET .../reports/company\|governorate` | Admin role required |

Error: `SQUAD_MEMBERSHIP_REQUIRED` → Orange **50**.

Mobile UI also shows locked panels for users without squads (defence in depth).

---

## 4. Internal service authentication

Service-to-service routes are **not** public. They require:

```http
X-Internal-Service-Token: {INTERNAL_SERVICE_TOKEN}
```

| Route | Guard | Caller |
|-------|-------|--------|
| `POST /user/api/v1/users/ensure` | `InternalServiceGuard` | auth-service (post sign-in) |
| `PUT /user/api/v1/users/:id/squad` | `InternalOrAdminGuard` | squad-service sync **or** admin JWT |

**Production:** Do not expose these on public Apigee products without IP allowlist + token policy. Default demo token: `demo-internal-sync` — **rotate in production**.

Config: `INTERNAL_SERVICE_TOKEN` in `.env` (see `.env.example`).

---

## 5. Implemented security controls

| Control | Layer | Details |
|---------|-------|---------|
| JWT access + refresh | API | Global guard; `@Public()` exceptions only |
| RBAC | API | `RolesGuard` + `@Roles()` |
| Input validation | API | Global `ValidationPipe` (whitelist, transform) |
| Orange error envelope | API | No stack traces to clients; numeric codes |
| Security headers | API | `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Cache-Control: no-store`, `Referrer-Policy`, `Permissions-Policy` |
| CORS | API | Dev/demo origins; extend via `CORS_ALLOWED_ORIGINS` |
| Secrets in git | Repo | `.env` gitignored; template in `.env.example` only |
| Mobile token storage | Mobile | Native: `flutter_secure_storage`; Web demo: localStorage (LAN/tunnel only) |
| Demo UI gating | Mobile | Demo OTP banner only when `DEMO_MODE` or debug |
| nginx headers | Gateway / Admin | `nginx-api-gateway.conf`, `nginx-admin.conf` |
| Gallery upload limit | API | Max 20 uploads per user (demo) |
| Squad IDOR mitigation | API | User id + squad id validated against profile on writes |

### Key files to review

```
.env.example
myboss-backend/libs/common/src/modules/security.module.ts
myboss-backend/libs/common/src/guards/jwt-auth.guard.ts
myboss-backend/libs/common/src/guards/roles.guard.ts
myboss-backend/libs/common/src/guards/internal-service.guard.ts
myboss-backend/libs/common/src/middleware/security-headers.middleware.ts
myboss-backend/libs/common/src/filters/http-exception.filter.ts
myboss-backend/libs/common/src/utils/cors.util.ts
myboss-backend/libs/common/src/utils/env.util.ts
myboss-mobile/lib/core/storage/secure_storage_service_mobile.dart
docker/nginx-api-gateway.conf
docker/nginx-admin.conf
myboss-admin/src/pages/LoginPage.tsx
```

---

## 6. Orange error responses (no information leakage)

All errors return:

```json
{
  "code": 50,
  "reason": "Access denied",
  "message": "Human-readable localized message",
  "infoURL": "https://api.orange.com/errors/50"
}
```

Server-side stack traces logged only for 5xx. Clients never receive raw exception messages in production filter path.

---

## 7. Verification commands

```bash
# Unauthenticated protected route → Orange 401
curl -s http://127.0.0.1:8090/squad/api/v1/squads/stats | jq .

# Full governance smoke test
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./scripts/verify-localhost.sh

# Security headers (example)
curl -sI http://127.0.0.1:8090/health | grep -i x-frame
```

---

## 8. Production hardening checklist

| Item | Demo state | Action before production |
|------|------------|--------------------------|
| Rate limiting | Not in app code | Apigee spike arrest (100 req/min/IP documented) |
| WAF / DDoS | Not in repo | Cloudflare / Apigee / cloud provider |
| TLS | HTTP locally | TLS at Apigee or load balancer |
| Account lockout | Not implemented | Define policy — see [`../OPEN_QUESTIONS.md`](../OPEN_QUESTIONS.md) |
| Penetration test | Not run | Schedule before go-live |
| Secret management | `.env` files | Vault / GCP Secret Manager / K8s secrets |
| MariaDB persistence | In-memory demo by default | Set `DB_ENABLED=true`; single `myboss` DB; encrypt at rest |
| Admin token storage | `localStorage` | Consider HttpOnly cookies + CSRF |
| Certificate pinning | Not implemented | Mobile production requirement TBD |
| Internal sync routes | Service token | IP allowlist on Apigee; rotate token |
| Demo OTP / credentials | Enabled in demo | Disable `TWO_FA_DEMO_ENABLED`; remove demo UI |
| Swagger | On in demo | Off in production (`APP_ENV=production`) |
| CORS | Dev/demo origins | Restrict to production domains |

---

## 9. Security review checklist

- [ ] `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN` rotated for each environment
- [ ] Orange errors do not leak internal paths or stack traces
- [ ] Protected endpoints return **401** (code 40/41) when unauthenticated
- [ ] Admin endpoints return **403** (code 50) for non-admin JWT
- [ ] Internal routes reject requests without valid service token
- [ ] CORS origins appropriate for environment
- [ ] Security headers present on API and gateway responses
- [ ] Mobile uses `flutter_secure_storage` on native release builds
- [ ] Demo 2FA clearly marked non-production
- [ ] Admin default password changed on shared demo servers
- [ ] Open items tracked in [`../OPEN_QUESTIONS.md`](../OPEN_QUESTIONS.md)

---

## 10. Known demo limitations

These are **acceptable for demo** but must be addressed for production:

1. In-memory data stores (no persistent DB encryption yet)
2. Demo OTP visible in API/logs when `TWO_FA_DEMO_ENABLED=true`
3. Web mobile stores tokens in localStorage (demo LAN/tunnel only)
4. No application-level rate limiting (delegated to Apigee)
5. Chat messages: in-memory when `DB_ENABLED=false`; persisted in `chat_messages` when DB enabled

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md) | Orange governance, Apigee |
| [`../database/DATABASE.md`](../database/DATABASE.md) | Schema & roles in DB |
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | Auth classes per endpoint |
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Deploy & env vars |
| [`../TEAM_REVIEW_GUIDE.md`](../TEAM_REVIEW_GUIDE.md) | Cross-team handoff |

---

*Orange — my boss app — Security*
