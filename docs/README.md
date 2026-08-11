# my boss app — Documentation

Central index for all project documentation.

---

## Start here by role

| Role | Primary guide | Also read |
|------|---------------|-----------|
| **New laptop or new phone** | [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md) | [`deployment/APIGEE_CLIENT_URLS.md`](deployment/APIGEE_CLIENT_URLS.md) |
| **All teams (handoff)** | [`TEAM_REVIEW_GUIDE.md`](TEAM_REVIEW_GUIDE.md) | Root [`README.md`](../README.md) |
| **DevOps / Infrastructure** | [`devops/DEVOPS.md`](devops/DEVOPS.md) | [`deployment/DEPLOYMENT.md`](deployment/DEPLOYMENT.md) |
| **Backend / Database** | [`database/DATABASE.md`](database/DATABASE.md) — **single shared MariaDB `myboss`** | [`api/API_OVERVIEW.md`](api/API_OVERVIEW.md), [`architecture/GOVERNANCE.md`](architecture/GOVERNANCE.md) |
| **Mobile** | [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) | [`PUSH_FIREBASE_SETUP.md`](PUSH_FIREBASE_SETUP.md), [`EMPLOYEE_JOURNEY_COVERAGE.md`](EMPLOYEE_JOURNEY_COVERAGE.md) |
| **Admin portal** | [`ADMIN_JOURNEY_COVERAGE.md`](ADMIN_JOURNEY_COVERAGE.md) | [myboss-admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) |
| **Security** | [`security/SECURITY.md`](security/SECURITY.md) | [`architecture/GOVERNANCE.md`](architecture/GOVERNANCE.md) |
| **Apigee / API Platform** | [`architecture/APIGEE_VS_NGINX.md`](architecture/APIGEE_VS_NGINX.md) | [`deployment/APIGEE_CLIENT_URLS.md`](deployment/APIGEE_CLIENT_URLS.md) |
| **External demo / APK** | [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md) | Error 1033, Cloudflare tunnel |
| **Push notifications** | [`PUSH_FIREBASE_SETUP.md`](PUSH_FIREBASE_SETUP.md) | Firebase, FCM, device tokens |
| **QA / Testing** | [`deployment/pdf/04_TESTING_GUIDE.md`](deployment/pdf/04_TESTING_GUIDE.md) | [`TEAM_REVIEW_GUIDE.md`](TEAM_REVIEW_GUIDE.md) |

---

## Demo testing (before each session)

In-memory data changes during testing. Reset squads, terms acceptance, and seed users:

```bash
./scripts/reset-demo-data.sh
```

| Email | Purpose |
|-------|---------|
| `demo@orange.com` | Full flow — Amman squad member |
| `nisreen.a@orange.com` | Squad **leader** — remove member, join requests |
| `omar.t@orange.com` | Onboarded, **no squad** — gating tests |
| `laila.m@orange.com` | **Onboarding incomplete** |
| `sara.h@orange.com` / `khaled.r@orange.com` | Irbid / Zarqa squad leaders |
| `admin@orange.com` | Admin console |

Seed IDs: `myboss-backend/libs/common/src/demo/demo-seed.constants.ts` · Full matrix: [`database/DATABASE.md` §8](database/DATABASE.md#8-demo-seed-accounts)

---

## Demo vs production gateway

| Demo (now) | Production (target) |
|------------|---------------------|
| nginx on `:8090` | **Orange Apigee** |
| Cloudflare quick tunnel (optional) | Apigee public URL |
| Same API paths: `/auth/api/v1`, `/user/api/v1`, … | Same paths |

Read: [`architecture/APIGEE_VS_NGINX.md`](architecture/APIGEE_VS_NGINX.md)

**External testers:** [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md) — tunnel, Error 1033, external APK

---

## Documentation map

```
docs/
├── README.md                    ← You are here
├── NEW_DEVICE_SETUP.md          ← New laptop + physical device (start here)
├── TEAM_REVIEW_GUIDE.md         ← Cross-team handoff
├── EMPLOYEE_JOURNEY_COVERAGE.md ← Mobile feature matrix
├── ADMIN_JOURNEY_COVERAGE.md    ← Admin feature matrix
├── OPEN_QUESTIONS.md            ← Pending product decisions
│
├── database/
│   └── DATABASE.md              ← CANONICAL schema (single `myboss` DB) + demo seed
├── devops/
│   └── DEVOPS.md                ← CANONICAL deploy & stack
├── mobile/
│   └── ANDROID_STUDIO.md        ← CANONICAL mobile build
├── security/
│   └── SECURITY.md              ← CANONICAL security
│
├── api/
│   ├── API_OVERVIEW.md          ← All REST endpoints
│   └── CHAT_API.md              ← Squad chat API
│
├── architecture/
│   ├── APIGEE_VS_NGINX.md       ← Demo nginx vs production Apigee
│   ├── ARCHITECTURE.md          ← System design (technical)
│   ├── HLD.md                   ← High-level (stakeholders)
│   ├── GOVERNANCE.md            ← Orange errors, Apigee, roles
│   ├── DATA_MODEL.md            ← Redirect → database/DATABASE.md
│   ├── GALLERY_NOTIFICATIONS.md
│   ├── NOTIFICATIONS_PRODUCTION.md
│   └── APIGEE_CHAT.md
│
├── deployment/
│   ├── DEPLOYMENT.md            ← Environment matrix
│   ├── DEMO_TUNNEL_AND_APK.md   ← Tunnel, Error 1033, external APK
│   ├── ENVIRONMENT_SETUP.md     ← Local dev (all apps)
│   ├── ENV_AND_GITLAB_VARIABLES.md ← All .env keys + GitLab CI/CD mapping
│   ├── IOS-URGENT-BUILD.md      ← iOS without local Xcode (supplementary)
│   └── pdf/                     ← Printable guides for Apigee & QA
│
└── cicd/
    └── CI_CD.md
```

### Canonical vs supplementary

| Type | Documents | Notes |
|------|-----------|-------|
| **Canonical** | `database/DATABASE.md`, `devops/DEVOPS.md`, `mobile/ANDROID_STUDIO.md`, `security/SECURITY.md` | Single source of truth — update these first |
| **Index / handoff** | This file, `TEAM_REVIEW_GUIDE.md`, root `README.md` | Point to canonical docs; avoid duplicating version tables |
| **Redirects** | `architecture/DATA_MODEL.md`, some `deployment/pdf/01_*.md`, `05_*.md` | Short stubs linking to canonical guides |
| **Coverage matrices** | `EMPLOYEE_JOURNEY_COVERAGE.md`, `ADMIN_JOURNEY_COVERAGE.md` | Track mockup/PDF vs implemented features |
| **Roadmap** | `OPEN_QUESTIONS.md`, `NOTIFICATIONS_PRODUCTION.md` | Not yet decided or not yet built |

---

## Quick commands

```bash
# Full demo stack (from myboss-platform)
cp .env.example .env
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway

# Reset demo data before team testing
./scripts/reset-demo-data.sh

# Optional: enable shared MariaDB (all services → database `myboss`)
# DB_ENABLED=true  MARIADB_DATABASE=myboss  — see docs/database/DATABASE.md

# Per-app local dev
cd ../myboss-backend && npm install && npm run start:dev
cd ../myboss-mobile && fvm flutter pub get && fvm flutter run --dart-define=DEMO_MODE=true
cd ../myboss-admin && npm install && npm run dev
```

---

## Application READMEs

Each app README lists **prerequisites**, **start steps**, **pinned versions**, and **files not in git**:

| App | Link |
|-----|------|
| Backend | [myboss-backend README](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md) |
| Mobile | [myboss-mobile README](https://github.com/areejobaid17894-blip/myboss-mobile/blob/main/README.md) |
| Admin | [myboss-admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) |
| Platform | [myboss-platform README](https://github.com/areejobaid17894-blip/myboss-platform/blob/main/README.md) |

### Git: what is committed vs ignored

| Committed (safe) | Ignored (never push) |
|------------------|----------------------|
| `.env.example`, `myboss-admin/.env.example` | `.env`, `.env.development`, `.env.demo`, … |
| Source code, docs, Dockerfiles, lockfiles | `node_modules/`, `build/`, `dist/`, APK |
| `demo-public-url.example.txt` (template) | `demo-public-url.txt` (live tunnel URL) |
| | `**/tsconfig.tsbuildinfo`, secrets (`*.pem`, `*.key`) |

**`.env.example` is intentional in git** — placeholders only. Copy to `.env` locally and use real secrets there.

---

*Orange — my boss app*
