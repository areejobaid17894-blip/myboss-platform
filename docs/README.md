# my boss app — Documentation

Central index for all project documentation.

---

## Start here by role

| Role | Primary guide | Also read |
|------|---------------|-----------|
| **New laptop or new phone** | [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md) | [`deployment/APIGEE_CLIENT_URLS.md`](deployment/APIGEE_CLIENT_URLS.md) |
| **DevOps / Infrastructure** | [`devops/DEVOPS.md`](devops/DEVOPS.md) | [`deployment/APIGEE_CONNECTION.md`](deployment/APIGEE_CONNECTION.md) |
| **Apigee / API Platform** | [`deployment/APIGEE_CONNECTION.md`](deployment/APIGEE_CONNECTION.md) | [`deployment/APIGEE_CLIENT_URLS.md`](deployment/APIGEE_CLIENT_URLS.md) |
| [`deployment/ORANGE_OTP_SETUP.md`](deployment/ORANGE_OTP_SETUP.md) | Orange OTP email |
| **QA / Testing** | [`deployment/TESTING.md`](deployment/TESTING.md) | [`TEAM_REVIEW_GUIDE.md`](TEAM_REVIEW_GUIDE.md) |
| **Backend / Database** | [`database/DATABASE.md`](database/DATABASE.md) | [`api/API_OVERVIEW.md`](api/API_OVERVIEW.md) |
| **Mobile** | [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) | [`PUSH_FIREBASE_SETUP.md`](PUSH_FIREBASE_SETUP.md) |
| **Admin portal** | [myboss-admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) | [`ADMIN_JOURNEY_COVERAGE.md`](ADMIN_JOURNEY_COVERAGE.md) |
| **Security** | [`security/SECURITY.md`](security/SECURITY.md) | [`architecture/GOVERNANCE.md`](architecture/GOVERNANCE.md) |
| **All teams (handoff)** | [`TEAM_REVIEW_GUIDE.md`](TEAM_REVIEW_GUIDE.md) | Root [`README.md`](../README.md) |

---

## Quick start (new machine)

```bash
# 1. Clone four repos as siblings (see NEW_DEVICE_SETUP.md)
# 2. Configure and deploy
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh

# 3. Admin (local dev — recommended)
cd ../myboss-admin && npm install && npm run dev
# → http://127.0.0.1:5173

# 4. Mobile (Apigee)
cd ../myboss-mobile
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

Full step-by-step: [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md)

---

## Demo testing (before each session)

```bash
./scripts/reset-demo-data.sh
```

| Email | Purpose |
|-------|---------|
| `demo@orange.com` | Full flow — Amman squad member |
| `nisreen.a@orange.com` | Squad **leader** |
| `omar.t@orange.com` | Onboarded, **no squad** |
| `laila.m@orange.com` | **Onboarding incomplete** |
| `admin@orange.com` | Admin console — password `admin123` |

---

## API gateway (current)

| Layer | URL |
|-------|-----|
| **Demo Apigee** | `https://api-demo.orange.com` |
| **Production Apigee** | `https://api.orange.com` |
| **Local backend (dev only)** | Direct ports `:3001–3006` |

There is **no nginx API gateway**. See [`architecture/APIGEE_VS_NGINX.md`](architecture/APIGEE_VS_NGINX.md).

---

## Documentation map

```
docs/
├── README.md                         ← You are here
├── NEW_DEVICE_SETUP.md               ← New laptop + phone (start here)
├── MULTI_REPO_SETUP.md               ← Developer workflows (four repos)
├── TEAM_REVIEW_GUIDE.md              ← Cross-team handoff
├── EMPLOYEE_JOURNEY_COVERAGE.md      ← Mobile feature matrix
├── ADMIN_JOURNEY_COVERAGE.md         ← Admin feature matrix
├── OPEN_QUESTIONS.md                 ← Pending product decisions
├── PUSH_FIREBASE_SETUP.md            ← FCM / push notifications
│
├── database/DATABASE.md              ← Schema + demo seed
├── devops/DEVOPS.md                  ← Deploy, verify, firewall
├── mobile/ANDROID_STUDIO.md          ← Flutter / emulator / APK
├── security/SECURITY.md              ← JWT, roles, secrets
│
├── api/
│   ├── API_OVERVIEW.md
│   └── CHAT_API.md
│
├── architecture/
│   ├── APIGEE_VS_NGINX.md
│   ├── ARCHITECTURE.md
│   ├── HLD.md
│   ├── GOVERNANCE.md
│   ├── GALLERY_NOTIFICATIONS.md
│   ├── NOTIFICATIONS_PRODUCTION.md
│   └── APIGEE_CHAT.md
│
├── deployment/
│   ├── DEPLOYMENT.md
│   ├── ENVIRONMENT_SETUP.md
│   ├── ENV_AND_GITLAB_VARIABLES.md
│   ├── APIGEE_CLIENT_URLS.md
│   ├── APIGEE_CONNECTION.md          ← Apigee team wiring
│   └── TESTING.md                    ← QA smoke tests
│
└── cicd/CI_CD.md
```

---

## Platform scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh [HOST]` | Backend + admin Docker |
| `verify-backend.sh` | Health :3001–3006 |
| `verify-mobile-api.sh [HOST]` | API governance (direct ports) |
| `verify-mobile-api.sh --apigee` | API governance via Apigee |
| `reset-demo-data.sh` | Restore demo seed |
| `stop-demo-server.sh` | Stop stack |
| `install-demo-server.sh [DIR]` | One-time VM setup |
| `fix-admin-login.sh` | Fix admin password |

---

## Application READMEs

| App | Link |
|-----|------|
| Backend | [myboss-backend README](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md) |
| Mobile | [myboss-mobile README](https://github.com/areejobaid17894-blip/myboss-mobile/blob/main/README.md) |
| Admin | [myboss-admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) |
| Platform | [myboss-platform README](https://github.com/areejobaid17894-blip/myboss-platform/blob/main/README.md) |

---

*Orange — my boss app*
