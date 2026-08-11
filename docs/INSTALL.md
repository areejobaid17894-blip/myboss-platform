# Install & run — my boss app

Installation sheet for developers and DevOps. Run the full stack **locally** on one machine.

Clients call **microservices directly** on ports **3001–3006**. No Apigee. No nginx API gateway.

---

## Prerequisites checklist

Install and verify before cloning:

| Tool | Required version | Verify command | Install |
|------|------------------|----------------|---------|
| **Git** | 2.x+ | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Docker Desktop** | **24+** (Compose v2) | `docker --version && docker compose version` | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Node.js** | **20 LTS** | `node --version` → v20.x | [nodejs.org](https://nodejs.org/) |
| **npm** | 10+ (bundled with Node 20) | `npm --version` | — |
| **Flutter** | **3.35.7** | `fvm flutter --version` | `brew install fvm && fvm install 3.35.7` |
| **Android Studio** | Latest | — | Only for mobile emulator/APK |

---

## Pinned stack versions

| Component | Version | Repo |
|-----------|---------|------|
| **Node.js** | 20 LTS | backend, admin, Docker |
| **TypeScript** | **5.9.3** | backend + admin (same version) |
| **NestJS** | 10.4 | myboss-backend |
| **React** | 19 | myboss-admin |
| **Vite** | 6 | myboss-admin |
| **Flutter** | 3.35.7 | myboss-mobile |
| **Dart** | ≥3.9.2 <4.0.0 | myboss-mobile |
| **Docker Compose** | v2 | myboss-platform |

---

## Step 1 — Clone all four repos

Repos must be **sibling folders**:

```bash
mkdir -p ~/myboss-repos && cd ~/myboss-repos

git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

```
myboss-repos/
├── myboss-backend/     NestJS — ports 3001–3006
├── myboss-admin/       React admin portal
├── myboss-mobile/      Flutter employee app
└── myboss-platform/    Docker, scripts, docs
```

---

## Step 2 — Configure environment

```bash
cd ~/myboss-repos/myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Edit `.env` — minimum for local demo:

```env
JWT_SECRET=<run: openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<run: openssl rand -base64 32>
DEMO_ADMIN_PASSWORD=admin123
DEMO_HOST=127.0.0.1
```

Full variable list: [`.env.example`](../.env.example)

---

## Step 3 — Deploy with Docker

```bash
cd ~/myboss-repos/myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
```

**Expected:** all health checks pass on ports 3001–3006.

---

## Step 4 — Open apps (local URLs)

| App | URL | Login |
|-----|-----|-------|
| **Admin (Docker)** | http://127.0.0.1:8081/login | `admin@orange.com` / `admin123` |
| **Admin (Vite dev)** | http://127.0.0.1:5173 | same — see Step 5 |
| **Employee web** | http://127.0.0.1:8092 | `demo@orange.com` + OTP — see Step 7 |
| **Auth Swagger** | http://127.0.0.1:3001/api/v1/docs | — |

**All API bases:** `http://127.0.0.1:3001/api/v1` … `http://127.0.0.1:3006/api/v1`

| Service | Swagger |
|---------|---------|
| auth | http://127.0.0.1:3001/api/v1/docs |
| user | http://127.0.0.1:3002/api/v1/docs |
| config | http://127.0.0.1:3003/api/v1/docs |
| squad | http://127.0.0.1:3004/api/v1/docs |
| survey | http://127.0.0.1:3005/api/v1/docs |
| notification | http://127.0.0.1:3006/api/v1/docs |

OTP auto-fills in demo mode.

---

## Step 5 — Admin portal (Vite dev — optional)

For UI development with hot reload:

```bash
cd ~/myboss-repos/myboss-admin
cp .env.example .env.development
npm install          # uses TypeScript 5.9.3
npm run dev
```

Open http://127.0.0.1:5173 — APIs call `localhost:3001–3005`.

Backend Docker (Step 3) must still be running.

---

## Step 6 — Mobile app (emulator)

```bash
cd ~/myboss-repos/myboss-mobile
fvm use 3.35.7
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

Android emulator reaches the host via `10.0.2.2` automatically.

---

## Step 7 — Employee web app (browser)

```bash
cd ~/myboss-repos/myboss-mobile
./run-local-web.sh
```

Open http://127.0.0.1:8092 — login `demo@orange.com`.

---

## Platform scripts

Run from `myboss-platform/`:

| Script | Purpose |
|--------|---------|
| `./scripts/deploy-demo-server.sh 127.0.0.1` | Start backend + admin Docker |
| `./scripts/verify-backend.sh` | Health check :3001–3006 |
| `./scripts/verify-mobile-api.sh 127.0.0.1` | API smoke test |
| `./scripts/reset-demo-data.sh` | Restore demo seed data |
| `./scripts/stop-demo-server.sh` | Stop all containers |
| `./scripts/fix-admin-login.sh` | Fix admin password issues |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Admin shows "Network error" | Re-run `./scripts/deploy-demo-server.sh 127.0.0.1` |
| Port already in use | `./scripts/stop-demo-server.sh` then redeploy |
| Mobile can't reach API | Backend must be running; use `ENV=development` on emulator |
| Admin login fails | `./scripts/fix-admin-login.sh` |
| Docker not running | Start Docker Desktop, wait until ready, redeploy |

---

## DevOps / VM

Server install (Ubuntu 22.04, CI/CD): [`devops/DEVOPS.md`](devops/DEVOPS.md)

QA smoke tests: [`deployment/TESTING.md`](deployment/TESTING.md)

---

*Orange — my boss app*
