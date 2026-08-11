# Install & run — my boss app

Single guide for developers and DevOps to run the full stack **locally** on one machine.

Clients call **microservices directly** on ports **3001–3006**. No Apigee. No nginx API gateway.

---

## 1. Required tools (pinned versions)

| Tool | Version | Install |
|------|---------|---------|
| **Git** | 2.x+ | [git-scm.com](https://git-scm.com/) |
| **Docker Desktop** | **24+** (Compose v2) | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Node.js** | **20 LTS** | [nodejs.org](https://nodejs.org/) |
| **Flutter** | **3.35.7** | `brew install fvm && fvm install 3.35.7` |
| **Dart** | **≥3.9.2 <4.0.0** | Bundled with Flutter |
| **Android Studio** | Latest | Only if running mobile emulator/APK |

**Stack locked in repo:**

| Component | Version |
|-----------|---------|
| NestJS | 10.4 |
| TypeScript (backend) | 5.9.3 |
| TypeScript (admin) | 5.7.3 |
| React | 19 |
| Vite | 6 |

---

## 2. Clone all four repos

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

## 3. Configure environment

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

## 4. Deploy (Docker)

```bash
cd ~/myboss-repos/myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
```

**Expected:** all health checks pass on ports 3001–3006.

---

## 5. Local URLs

| App | URL |
|-----|-----|
| **Admin (Docker)** | http://127.0.0.1:8081/login |
| **Admin (Vite dev)** | http://127.0.0.1:5173 — see §6 |
| **Employee web** | http://127.0.0.1:8092 — see §8 |
| **Auth Swagger** | http://127.0.0.1:3001/api/v1/docs |
| **User Swagger** | http://127.0.0.1:3002/api/v1/docs |
| **Config Swagger** | http://127.0.0.1:3003/api/v1/docs |
| **Squad Swagger** | http://127.0.0.1:3004/api/v1/docs |
| **Survey Swagger** | http://127.0.0.1:3005/api/v1/docs |
| **Notification Swagger** | http://127.0.0.1:3006/api/v1/docs |

**API base URLs:** `http://127.0.0.1:3001/api/v1` … `http://127.0.0.1:3006/api/v1`

---

## 6. Admin portal (Vite dev — optional)

Use when editing admin UI with hot reload:

```bash
cd ~/myboss-repos/myboss-admin
cp .env.example .env.development
npm install
npm run dev
```

Open http://127.0.0.1:5173 — APIs call `localhost:3001–3005`.

---

## 7. Mobile app — emulator

```bash
cd ~/myboss-repos/myboss-mobile
fvm use 3.35.7
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

Android emulator reaches the host via `10.0.2.2` automatically.

---

## 8. Employee web app — browser

```bash
cd ~/myboss-repos/myboss-mobile
./run-local-web.sh
```

Open http://127.0.0.1:8092

---

## 9. Logins (demo)

| App | Email | Password / OTP |
|-----|-------|----------------|
| Admin | `admin@orange.com` | `admin123` → OTP auto-fills |
| Employee | `demo@orange.com` | OTP auto-fills in demo mode |

---

## 10. Useful scripts

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

## 11. Troubleshooting

| Problem | Fix |
|---------|-----|
| Admin shows "Network error" | Rebuild admin: `./scripts/deploy-demo-server.sh 127.0.0.1` (sets `DEMO_HOST=127.0.0.1`) |
| Port already in use | `./scripts/stop-demo-server.sh` then redeploy |
| Mobile can't reach API | Backend must be running; use `ENV=development` on emulator |
| Admin login fails | `./scripts/fix-admin-login.sh` |

---

## DevOps / VM

For server install (Ubuntu 22.04, firewall, CI/CD): [`devops/DEVOPS.md`](devops/DEVOPS.md)

For QA verification: [`deployment/TESTING.md`](deployment/TESTING.md)

---

*Orange — my boss app*
