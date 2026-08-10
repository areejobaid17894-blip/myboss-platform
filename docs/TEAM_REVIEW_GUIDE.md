# my boss app — Team Review & Handoff Guide

**Purpose:** Single entry point for DevOps, Security, Apigee, Mobile, Backend, Admin, QA, and Architecture teams to review the platform before go-live.

**Repositories:** multi-repo — see [MULTI_REPO_SETUP.md](MULTI_REPO_SETUP.md)  
**Current phase:** Demo-ready (Orange governance-aligned APIs, JWT + 2FA demo, Swagger, native chat)

---

## Quick links by team

| Team | Start here | Primary verification |
|------|------------|----------------------|
| **DevOps / Infrastructure** | [`docs/devops/DEVOPS.md`](devops/DEVOPS.md) | `deploy-demo-server.sh`, `verify-backend.sh` |
| **Security / Compliance** | [`docs/security/SECURITY.md`](security/SECURITY.md) | JWT, Orange errors, internal token |
| **Apigee / API Platform** | [`docs/deployment/pdf/03_APIGEE_CONNECTION.md`](deployment/pdf/03_APIGEE_CONNECTION.md) | Swagger |
| **Backend development** | [`../../myboss-backend/README.md`](../../myboss-backend/README.md) | `verify-mobile-api.sh` |
| **Mobile (Android / iOS)** | [`docs/mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) | APK build |
| **Admin portal** | [`ADMIN_JOURNEY_COVERAGE.md`](ADMIN_JOURNEY_COVERAGE.md) | Gateway `/login` |
| **QA / Testing** | [`docs/deployment/pdf/04_TESTING_GUIDE.md`](deployment/pdf/04_TESTING_GUIDE.md) | Testing guide |
| **Database** | [`docs/database/DATABASE.md`](database/DATABASE.md) | Schema review |
| **Architecture / Product** | [`architecture/HLD.md`](architecture/HLD.md) | HLD, ARCHITECTURE |

---

## Technology stack & versions

Pinned versions for reproducible builds. CI uses Node **20**; mobile CI uses Flutter **stable** (local dev pins **3.35.7** via FVM).

### Runtime & languages

| Component | Version | Notes |
|-----------|---------|-------|
| **Node.js** | 20 LTS (`node:20-alpine` in Docker) | Backend + admin build; GitHub Actions `node-version: '20'` |
| **TypeScript (backend)** | ^5.4.0 → **5.9.3** locked | `myboss-backend/package-lock.json` |
| **TypeScript (admin)** | ~5.7.0 → **5.7.3** locked | `myboss-admin/package-lock.json` |
| **Flutter** | **3.35.7** | `myboss-mobile/pubspec.yaml`, `myboss-mobile/.fvmrc` |
| **Dart** | **^3.9.2** (>=3.9.2 <4.0.0) | `myboss-mobile/pubspec.yaml` |

### Backend (NestJS microservices)

| Package | Declared | Locked (root lockfile) |
|---------|----------|------------------------|
| @nestjs/common / core | ^10.3.0 | 10.4.22 |
| @nestjs/swagger | ^7.3.0 | 7.4.2 |
| @nestjs/jwt | ^10.2.0 | 10.2.0 |
| @nestjs/passport | ^10.0.3 | 10.0.3 |
| express (transitive) | — | 4.22.1 |
| jsonwebtoken | — | 9.0.2 |
| passport-jwt | ^4.0.1 | 4.0.1 |
| class-validator | ^0.14.1 | 0.14.4 |
| swagger-ui-dist | — | 5.17.14 |
| jest | ^29.7.0 | 29.7.0 |

**Services:** auth (3001), user (3002), config (3003), squad (3004), survey (3005)  
**Shared library:** `myboss-backend/libs/common` (Orange errors, JWT, Swagger, CORS, security headers)

### Admin portal

| Package | Declared | Locked |
|---------|----------|--------|
| React | ^19.0.0 | 19.2.8 |
| react-dom | ^19.0.0 | 19.2.8 |
| react-router-dom | ^7.5.0 | 7.18.1 |
| Vite | ^6.2.0 | 6.4.3 |
| axios | ^1.8.4 | 1.18.1 |
| vitest | ^3.1.0 | 3.2.7 |

### Mobile (Flutter)

| Package | Declared | Locked |
|---------|----------|--------|
| flutter_bloc | ^9.1.0 | 9.1.1 |
| dio | ^5.8.0 | 5.10.0 |
| go_router | ^15.1.2 | 15.1.3 |
| flutter_secure_storage | ^9.2.4 | 9.2.4 |
| get_it | ^8.0.3 | 8.3.0 |

**App version:** 1.0.0+1

### Infrastructure (Docker images)

| Image | Tag | Usage |
|-------|-----|--------|
| node | 20-alpine | Backend service builds |
| nginx | alpine | Admin portal container |
| nginx | 1.27-alpine | API gateway (port 8090) |
| mariadb | 11.4 | Shared database `myboss` (optional `with-mariadb` profile) |
| redis | 7-alpine | Local/dev cache (optional compose) |

### External tools (demo)

| Tool | Version / notes |
|------|-----------------|
| cloudflared | 2026.7.2+ (quick tunnel for external demo) |
| Docker Compose | v2+ |
| FVM | Flutter version manager — `myboss-mobile/.fvmrc` |

---

## Server specifications

### Demo event profile

| Item | Specification |
|------|---------------|
| **Event duration** | ~1 week |
| **Expected load** | ~1,500 users/day |
| **Environment** | Demo (pre-production) |

### Minimum demo server (VM)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **CPU** | 2 vCPU | 4 vCPU |
| **RAM** | 4 GB | 8 GB |
| **Disk** | 30 GB SSD | 50 GB SSD |
| **Docker** | 24+ with Compose v2 | Latest stable |

### Network ports

| Port | Service | Exposure |
|------|---------|----------|
| **8090** | API gateway (nginx) — mobile web `/app/`, admin `/login`, all API proxies | Public via Apigee or Cloudflare tunnel |
| **3001** | auth-service | Apigee / internal only (not public in production) |
| **3002** | user-service | Apigee / internal only |
| **3003** | config-service (+ Chat API) | Apigee / internal only |
| **3004** | squad-service | Apigee / internal only |
| **3005** | survey-service (+ gallery) | Apigee / internal only |
| **8081** | admin-portal (direct nginx) | Optional; prefer gateway **8090/login** |
| **3306** | MariaDB | Internal only (when `DB_ENABLED=true`) |
| **6379** | Redis | Internal only (future cache/sessions) |
| **5173** | Vite dev server | Local development only |

### Docker containers (demo stack)

| Container | Image / build | Health |
|-----------|---------------|--------|
| myboss-auth | `Dockerfile.auth` | `/api/v1/health` |
| myboss-user | `Dockerfile.user` | `/api/v1/health` |
| myboss-config | `Dockerfile.config` | `/api/v1/health` |
| myboss-squad | `Dockerfile.squad` | `/api/v1/health` |
| myboss-survey | `Dockerfile.survey` | `/api/v1/health` |
| myboss-admin | `Dockerfile.admin-portal` | nginx (profile `with-admin`) |
| myboss-api-gateway | nginx:1.27-alpine | `/health` → `OK` |

**Compose file:** `docker/docker-compose.demo.yml`  
**Gateway:** deployed separately via `scripts/deploy-mobile-web.sh` (port **8090**)

### Apigee path mapping (production target)

| Apigee prefix | Backend | Example |
|---------------|---------|---------|
| `/auth/api/v1/**` | auth-service:3001 | `POST /auth/sign-in` |
| `/user/api/v1/**` | user-service:3002 | `GET /users/{id}` |
| `/config/api/v1/**` | config-service:3003 | `GET /chat/messages` |
| `/squad/api/v1/**` | squad-service:3004 | `GET /squads/stats` |
| `/survey/api/v1/**` | survey-service:3005 | `GET /surveys/catalog` |

Full guide: [`docs/deployment/pdf/03_APIGEE_CONNECTION.md`](deployment/pdf/03_APIGEE_CONNECTION.md)

---

## Orange governance coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Orange error envelope `{ code, reason, message, infoURL? }` | **Implemented** | `myboss-backend/libs/common/src/errors/orange-error-codes.ts`, `http-exception.filter.ts` |
| Numeric Orange codes (40, 41, 42, 50, 60, 69, …) | **Implemented** | Mapped in `orange-error-codes.ts` |
| JWT authentication on protected routes | **Implemented** | Global `JwtAuthGuard`; `@Public()` for open routes |
| RBAC (ADMIN role) | **Implemented** | `RolesGuard` + `@Roles()` |
| Swagger / OpenAPI per service | **Implemented** | `/api/v1/docs` when `APP_ENV=demo\|development` or `SWAGGER_ENABLED=true` |
| Apigee-style URL paths | **Implemented** | Gateway nginx proxies `/auth/`, `/user/`, etc. |
| 2FA endpoint naming `verify-2fa` | **Implemented** | `POST /auth/verify-2fa` (not `verify-otp`) |
| Governance smoke test script | **Implemented** | `scripts/verify-mobile-api.sh` |
| Chat API under config service | **Implemented** | `docs/api/CHAT_API.md` |
| Rate limiting | **Apigee responsibility** | Documented spike arrest 100 req/min/IP in Apigee guide |
| Production 2FA provider | **Demo only** | `TWO_FA_DEMO_ENABLED=true`; static OTP in demo mode |

**Run governance verification:**

```bash
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./scripts/verify-localhost.sh
```

---

## Security overview

### Implemented controls

| Control | Layer | Details |
|---------|-------|---------|
| **JWT access + refresh tokens** | API | `JWT_SECRET`, `JWT_EXPIRES_IN=15m`, `JWT_REFRESH_EXPIRES_IN=7d` in `.env.example` |
| **Weak secret rejection** | API | Boot fails if `JWT_SECRET` is default when `APP_ENV≠development` |
| **Global JWT guard** | API | All routes protected unless `@Public()` |
| **RBAC** | API | Role-based access for admin endpoints |
| **Input validation** | API | Global `ValidationPipe` (whitelist, transform) |
| **Security headers** | API | `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Cache-Control: no-store`, `Referrer-Policy`, `Permissions-Policy` — `security-headers.middleware.ts` |
| **CORS** | API | Configured for dev/demo; extend via `CORS_ALLOWED_ORIGINS` |
| **2FA (demo)** | Auth | Email OTP flow; demo auto-fill when `DEMO_MODE=true` |
| **Orange error format** | API | No stack traces leaked to clients in production filter |
| **Secrets in git** | Repo | `.env` gitignored; template in `.env.example` only |
| **Mobile token storage** | Mobile | Native: `flutter_secure_storage`; Web demo: localStorage (LAN/tunnel only) |
| **Demo UI gating** | Mobile | Demo accounts / OTP banner only when `DEMO_MODE` or debug |
| **nginx security headers** | Gateway / Admin | Admin portal Docker nginx config |

### Production hardening (Security team action items)

| Item | Current state | Recommended action |
|------|---------------|-------------------|
| Rate limiting | Not in application code | Configure Apigee spike arrest + OAuth policies |
| WAF / DDoS | Not in repo | Cloudflare / Apigee / cloud provider |
| TLS termination | Demo uses HTTP locally | TLS at Apigee or load balancer in production |
| Account lockout | Not implemented | Define policy — see `docs/OPEN_QUESTIONS.md` |
| Penetration test | Not run | Schedule before production |
| Secret management | `.env` files | Vault / GCP Secret Manager / K8s secrets |
| MariaDB / Redis | Compose available; demo defaults to in-memory | Set `DB_ENABLED=true` for shared `myboss` DB |
| Admin token storage | `localStorage` | Consider HttpOnly cookies + CSRF for production |
| Certificate pinning | Not implemented | Mobile production requirement TBD |
| Helmet (npm) | Not used | Custom middleware covers core headers; review parity |

**Security-related files to review:**

- `.env.example` — all configurable secrets
- `myboss-backend/libs/common/src/modules/security.module.ts`
- `myboss-backend/libs/common/src/guards/jwt-auth.guard.ts`
- `myboss-backend/libs/common/src/middleware/security-headers.middleware.ts`
- `myboss-backend/libs/common/src/utils/cors.util.ts`
- `myboss-backend/libs/common/src/utils/env.util.ts` — JWT secret validation
- `myboss-mobile/lib/core/storage/secure_storage_service_mobile.dart`
- `docker/nginx-api-gateway.conf`

---

## DevOps / Infrastructure team

### What you need

1. Ubuntu 22.04 VM (specs above)
2. Docker 24+ and Compose v2
3. `.env` from `.env.example` with strong `JWT_SECRET`
4. Firewall: expose **8090** (gateway) to Apigee or Cloudflare; restrict **3001–3005** to Apigee IP range

### Documents

| Document | Path |
|----------|------|
| **DevOps guide (primary)** | `docs/devops/DEVOPS.md` |
| Run demo server | `docs/deployment/pdf/02_RUN_DEMO_SERVER.md` |
| Deployment overview | `docs/deployment/DEPLOYMENT.md` |
| Environment setup | `docs/deployment/ENVIRONMENT_SETUP.md` |
| CI/CD | `docs/cicd/CI_CD.md` |
| Docker README | `docker/README.md` |

### Deploy commands

```bash
cp .env.example .env          # set JWT_SECRET, DEMO_HOST
./scripts/deploy-demo-server.sh <SERVER_IP>
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/start-demo-tunnel.sh    # optional public URL
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

### CI/CD workflows (GitHub Actions)

| Workflow | File | Trigger |
|----------|------|---------|
| Backend CI | `myboss-backend/.gitlab-ci.yml` | push → backend repo |
| Admin CI | `myboss-admin/.gitlab-ci.yml` | push → admin repo |
| Mobile CI | `myboss-mobile/.gitlab-ci.yml` | push → mobile repo |
| Platform docs/deploy | `myboss-platform/.gitlab-ci.yml` | push → platform repo |

**Note:** Deploy jobs in CI are placeholders (`echo` only). Wire to your registry/K8s before production.

### DevOps checklist

- [ ] VM meets CPU/RAM/disk specs
- [ ] Docker images build from `docker/Dockerfile.*`
- [ ] Gateway **8090** serves `/app/`, `/login`, and API proxies
- [ ] `verify-backend.sh` passes
- [ ] `verify-mobile-api.sh --gateway` passes
- [ ] Firewall rules documented and applied
- [ ] Secrets not committed; `JWT_SECRET` rotated for demo
- [ ] Cloudflare tunnel or Apigee URL documented in `demo-public-url.txt`

---

## Security / Compliance team

### What you need

1. [`docs/security/SECURITY.md`](security/SECURITY.md) — primary security guide
2. Access to demo environment (gateway URL or tunnel)
3. Swagger docs for API review
4. `.env.example` for secrets inventory

### Review checklist

See full checklist in [`docs/security/SECURITY.md`](security/SECURITY.md). Summary:
- [ ] Orange error responses do not leak internal details
- [ ] All protected endpoints return 401 with Orange envelope when unauthenticated
- [ ] CORS origins appropriate for demo vs production
- [ ] Security headers on API responses
- [ ] Mobile secure storage on native builds
- [ ] Demo 2FA clearly marked non-production (`TWO_FA_DEMO_ENABLED`)
- [ ] Admin credentials changed from defaults in non-local deploys
- [ ] Open items in `docs/OPEN_QUESTIONS.md` (lockout, pen test, compliance frameworks)

### Verification commands

```bash
# Unauthenticated protected route → Orange 401
curl -s http://127.0.0.1:8090/squad/api/v1/squads/stats | jq .

# Authenticated flow (governance script)
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

### Documents

| Document | Path |
|----------|------|
| **Security guide (primary)** | `docs/security/SECURITY.md` |
| Architecture (security layers) | `docs/architecture/ARCHITECTURE.md` |
| Governance | `docs/architecture/GOVERNANCE.md` |
| API overview (auth, errors) | `docs/api/API_OVERVIEW.md` |
| Open security questions | `docs/OPEN_QUESTIONS.md` § Security & Compliance |
| Apigee policies (rate limit, JWT) | `docs/deployment/pdf/03_APIGEE_CONNECTION.md` |

---

## Apigee / API Platform team

### What you need

1. Demo VM IP or public tunnel base URL
2. Swagger URLs for all five services
3. Public vs protected route list

### Documents

| Document | Path |
|----------|------|
| Apigee connection guide | `docs/deployment/pdf/03_APIGEE_CONNECTION.md` |
| Chat + Apigee | `docs/architecture/APIGEE_CHAT.md` |
| Chat REST API | `docs/api/CHAT_API.md` |
| API overview | `docs/api/API_OVERVIEW.md` |

### Public routes (no JWT)

- `POST /auth/api/v1/auth/sign-in`
- `POST /auth/api/v1/auth/sign-up`
- `POST /auth/api/v1/auth/verify-2fa`
- `POST /auth/api/v1/auth/refresh`
- `GET /config/api/v1/config/buildings`
- `GET /config/api/v1/chat/config`
- `GET /*/api/v1/health`
- `GET /*/api/v1/docs` (non-production)

### Apigee checklist

- [ ] Five proxies: auth, user, config, squad, survey
- [ ] Base path `/service/api/v1` matches backend
- [ ] Spike arrest policy (recommended 100 req/min/IP)
- [ ] JWT verify policy on protected routes
- [ ] CORS for admin + mobile web origins
- [ ] TLS termination at edge
- [ ] Chat routes on config proxy (no separate chat proxy)

---

## Backend development team

### What you need

- Node.js 20, npm 10+
- Repo root `.env`
- Docker (optional) for full stack

### Documents

| Document | Path |
|----------|------|
| Backend README | `myboss-backend/README.md` |
| API overview | `docs/api/API_OVERVIEW.md` |
| Chat API | `docs/api/CHAT_API.md` |
| Orange error codes | `myboss-backend/libs/common/src/errors/orange-error-codes.ts` |

### Local commands

```bash
cd myboss-backend
npm install
npm run docker:up      # Postgres + Redis (future use)
npm run start:dev      # all 5 services
npm run test           # unit tests per service
npm run lint
```

### Backend checklist

- [ ] All services expose `/api/v1/health` and `/api/v1/docs`
- [ ] `@Public()` only on intended routes
- [ ] Orange errors for all thrown `AppException`s
- [ ] Swagger tags match governance (Auth, User, Config, Chat, Squad, Survey)

---

## Mobile team

### What you need

- Flutter **3.35.7** / Dart **3.9.2** (FVM)
- Android Studio (emulator) or physical device
- Demo gateway on **8090**

### Documents

| Document | Path |
|----------|------|
| Mobile README | `myboss-mobile/README.md` |
| Android guide (PDF) | `docs/deployment/pdf/05_ANDROID_STUDIO_MOBILE.md` |
| iOS urgent build | `docs/deployment/IOS-URGENT-BUILD.md` |

### Build commands

```bash
cd myboss-mobile
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
./build-local-android.sh          # release APK
./build-demo-ios.sh --ipa         # iOS (Xcode required)
```

### Mobile checklist

- [ ] `DEMO_MODE=true` probes gateway at startup
- [ ] Sign-in + 2FA flow works via gateway
- [ ] Demo UI hidden in non-demo release builds
- [ ] Native: tokens in `flutter_secure_storage`
- [ ] EN + AR localization (`l10n/`)

---

## Admin portal team

### What you need

- Node.js 20
- Gateway URL for API calls (demo: same origin via **8090/login**)
- Design reference: **the Boss — Admin Console V2** (black sidebar, 11 sections)

### Documents

| Document | Path |
|----------|------|
| Admin README | `myboss-admin/README.md` |
| Admin journey matrix | `docs/ADMIN_JOURNEY_COVERAGE.md` |
| Data model | `docs/architecture/DATA_MODEL.md` |
| Env files | `myboss-admin/.env.demo`, `.env.docker` |

### Demo URLs

| Flow | Local | Public tunnel |
|------|-------|---------------|
| Admin login | http://127.0.0.1:8090/login | `https://<tunnel>/login` |
| Employee web | http://127.0.0.1:8090/app/ | `https://<tunnel>/app/` |
| Swagger (all services) | http://127.0.0.1:8090/{auth,user,config,squad,survey}/api/v1/docs | Same paths on tunnel host |

Current tunnel URL: **`demo-public-url.txt`** at repo root.

### Commands

```bash
cd myboss-admin
npm install
npm run dev              # http://localhost:5173
npm run build:demo       # production build for demo env
npm test
```

### Admin checklist

- [ ] Login via gateway `/login` (prefer **8090**, not raw :8081)
- [ ] V2 nav visible: Overview, Statistics, Squads, Destinations, …
- [ ] Overview loads KPIs without crash (uses `/squads/admin/all`)
- [ ] Assign unregistered persists via API
- [ ] Destinations save via `PUT /squads/:id/destination`
- [ ] API calls use gateway paths (`/auth`, `/user`, `/squad`, …)
- [ ] Demo credentials rotated on shared servers

---

## QA / Testing team

### Documents

| Document | Path |
|----------|------|
| Testing guide (PDF) | `docs/deployment/pdf/04_TESTING_GUIDE.md` |
| API overview | `docs/api/API_OVERVIEW.md` |
| Chat API | `docs/api/CHAT_API.md` |

### Automated verification

```bash
./scripts/verify-mobile-api.sh <HOST> --gateway
./scripts/verify-localhost.sh
```

### Demo test accounts

Run `./scripts/reset-demo-data.sh` before each test cycle to restore squads and clear terms acceptance.

| Email | Purpose |
|-------|---------|
| demo@orange.com | Full employee flow (Amman squad member) |
| nisreen.a@orange.com | Squad leader — remove member, join requests |
| laila.m@orange.com | Onboarding not completed |
| omar.t@orange.com | Onboarded, **no squad** — gating tests |
| sara.h@orange.com | Irbid squad leader |
| khaled.r@orange.com | Zarqa squad leader |
| admin@orange.com | Admin console (`/login`) |

**Journey coverage:** [`docs/EMPLOYEE_JOURNEY_COVERAGE.md`](EMPLOYEE_JOURNEY_COVERAGE.md)  
**Database schema & seed IDs:** [`docs/database/DATABASE.md`](database/DATABASE.md)

### QA checklist

- [ ] Employee sign-in + OTP (web and APK)
- [ ] Terms & conditions blocking popup after OTP (and on app restart if not accepted)
- [ ] Onboarding skip when vest + building already set
- [ ] Squad hub on login when no squad; continue without squad
- [ ] Squad browse (all squads + governorate filter) + join request
- [ ] Survey submission (in-squad user)
- [ ] Gallery upload (in squad); locked without squad
- [ ] Reports tab locked without squad
- [ ] Native chat (squad members); FAB on all tabs
- [ ] Admin login and **V2 console** (Overview, Statistics, Squads, …)
- [ ] Admin OTP/credentials prefill only when `VITE_APP_ENV=demo`
- [ ] Swagger try-it-out with JWT
- [ ] Arabic + English UI

---

## Architecture / Product team

### Documents

| Document | Path |
|----------|------|
| High-level design | `docs/architecture/HLD.md` |
| Architecture | `docs/architecture/ARCHITECTURE.md` |
| Data model (target schema) | `docs/database/DATABASE.md` |
| Employee journey coverage | `docs/EMPLOYEE_JOURNEY_COVERAGE.md` |
| Open questions | `docs/OPEN_QUESTIONS.md` |

### Scope delivered (demo phase)

- 5 NestJS microservices + API gateway pattern
- Flutter employee app (Android, iOS, web)
- React admin portal
- JWT + demo 2FA
- Orange governance error format
- OpenAPI / Swagger per service
- Native squad chat (config service)
- EN/AR localization (mobile)

### Out of scope / open (see OPEN_QUESTIONS.md)

- Production 2FA provider
- MariaDB persistence (TypeORM wired for auth/user/config/squad; enable with `DB_ENABLED=true`)
- Apigee production cutover
- Power BI reporting
- Push notifications — **in-app demo done**; production OS push via FCM/APNs (see [`NOTIFICATIONS_PRODUCTION.md`](architecture/NOTIFICATIONS_PRODUCTION.md))
- App store release pipeline

---

## Environment matrix

| Environment | `APP_ENV` | Swagger | 2FA | Database |
|-------------|-----------|---------|-----|----------|
| development | development | On | Demo | In-memory / local |
| demo | demo | On | Demo | In-memory (default) or MariaDB `myboss` |
| uat | uat | Configurable | TBD | MariaDB `myboss` |
| production | production | Off | Production provider | MariaDB `myboss` |

---

## Contact & escalation template

| Role | Responsibility | Contact |
|------|----------------|---------|
| **DevOps lead** | VM, Docker, gateway, tunnel, CI/CD | _[fill in]_ |
| **Security lead** | JWT, pen test, compliance sign-off | _[fill in]_ |
| **Apigee lead** | Proxies, policies, production URLs | _[fill in]_ |
| **Backend lead** | Microservices, Orange errors, APIs | _[fill in]_ |
| **Mobile lead** | Flutter Android/iOS/web builds | _[fill in]_ |
| **Admin lead** | React admin portal | _[fill in]_ |
| **QA lead** | Test plans, sign-off | _[fill in]_ |
| **Product owner** | Requirements, open questions | _[fill in]_ |

---

*Orange — my boss app — Team Review Guide*
