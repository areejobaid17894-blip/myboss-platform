# my boss app — Documentation

Central index for all project documentation.

---

## Start here by role

| Role | Primary guide | Also read |
|------|---------------|-----------|
| **New laptop or new phone** | [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md) | [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md) |
| **DevOps / VM deploy** | [`devops/DEVOPS.md`](devops/DEVOPS.md) | [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md) |
| **QA / Testing** | [`deployment/TESTING.md`](deployment/TESTING.md) | [`TEAM_REVIEW_GUIDE.md`](TEAM_REVIEW_GUIDE.md) |
| **Orange email OTP** | [`deployment/ORANGE_OTP_SETUP.md`](deployment/ORANGE_OTP_SETUP.md) | |
| **Backend / Database** | [`database/DATABASE.md`](database/DATABASE.md) | [`api/API_OVERVIEW.md`](api/API_OVERVIEW.md) |
| **Mobile** | [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) | [`PUSH_FIREBASE_SETUP.md`](PUSH_FIREBASE_SETUP.md) |
| **Admin portal** | [myboss-admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) | [`ADMIN_JOURNEY_COVERAGE.md`](ADMIN_JOURNEY_COVERAGE.md) |
| **Security** | [`security/SECURITY.md`](security/SECURITY.md) | [`architecture/GOVERNANCE.md`](architecture/GOVERNANCE.md) |

---

## Quick start

```bash
cd myboss-platform
cp .env.example .env && chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

| App | URL |
|-----|-----|
| Admin (Docker) | http://127.0.0.1:8081 |
| Admin (Vite dev) | http://127.0.0.1:5173 — `cd ../myboss-admin && npm run dev` |
| APIs | http://127.0.0.1:3001/api/v1 … :3006 |

**Deployed server:** replace `127.0.0.1` with your VM/LAN IP — see [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md).

---

## Architecture

Clients call **microservices directly** on ports **3001–3006**. No Apigee. No nginx API gateway.

---

## Documentation map

```
docs/
├── NEW_DEVICE_SETUP.md
├── MULTI_REPO_SETUP.md
├── devops/DEVOPS.md
├── deployment/
│   ├── SERVICE_URLS.md      ← Direct port URLs (local + deployed)
│   ├── ORANGE_OTP_SETUP.md
│   ├── TESTING.md
│   └── ENV_AND_GITLAB_VARIABLES.md
├── mobile/ANDROID_STUDIO.md
├── api/API_OVERVIEW.md
└── database/DATABASE.md
```

---

## Platform scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh [HOST]` | Backend + admin Docker |
| `verify-backend.sh` | Health :3001–3006 |
| `verify-mobile-api.sh [HOST]` | API smoke test |
| `verify-orange-otp.sh` | Orange SSO token test |
| `reset-demo-data.sh` | Restore demo seed |

---

*Orange — my boss app*
