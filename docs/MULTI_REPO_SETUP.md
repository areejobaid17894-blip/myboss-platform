# my boss app — Multi-repo setup

Four separate Git repositories that work together. Clone them as **siblings** in one folder:

```
myboss-repos/
├── myboss-mobile/      # Flutter employee app
├── myboss-admin/       # React admin portal
├── myboss-backend/     # NestJS microservices (5 services)
├── myboss-platform/    # Docs, Docker Compose, deploy scripts
└── README.md           # ← you are here
```

| Repo | GitHub |
|------|--------|
| myboss-mobile | https://github.com/areejobaid17894-blip/myboss-mobile |
| myboss-admin | https://github.com/areejobaid17894-blip/myboss-admin |
| myboss-backend | https://github.com/areejobaid17894-blip/myboss-backend |
| myboss-platform | https://github.com/areejobaid17894-blip/myboss-platform |

---

## 1. One-time installation (all developers)

Install these once on your machine:

| Tool | Version | Install |
|------|---------|---------|
| **Git** | Latest | [git-scm.com](https://git-scm.com/) |
| **Node.js** | **20 LTS** | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| **npm** | 10+ | Bundled with Node 20 |
| **Docker Desktop** | 24+ (Compose v2) | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Flutter** | **3.35.7** | [FVM](https://fvm.app): `brew install fvm && fvm install 3.35.7` |
| **Android Studio** | Latest | For Android emulator / APK builds |
| **cloudflared** | Optional | `brew install cloudflared` — public demo URL |

### Clone all four repos

```bash
mkdir -p ~/Desktop/myboss-repos && cd ~/Desktop/myboss-repos

git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

### Environment files (required before first run)

**Platform** (used by Docker deploy):

```bash
cd myboss-platform
cp .env.example .env
# Edit JWT_SECRET and INTERNAL_SERVICE_TOKEN (see below)
```

**Backend** (used by `npm run start:dev` without Docker):

```bash
cd ../myboss-backend
cp .env.example .env
# Use the same JWT_SECRET and INTERNAL_SERVICE_TOKEN as platform
```

**Admin** (used by Vite dev server):

```bash
cd ../myboss-admin
cp .env.example .env.development
```

Generate secrets:

```bash
openssl rand -base64 48   # JWT_SECRET
openssl rand -base64 32   # INTERNAL_SERVICE_TOKEN
```

---

## 2. Run locally — full demo stack (recommended)

This starts backend + admin in Docker, builds mobile web, and serves everything on **port 8090**.

```bash
cd myboss-platform
chmod +x scripts/*.sh

# Step 1 — backend + admin containers
./scripts/deploy-demo-server.sh 127.0.0.1

# Step 2 — Flutter web at /app/ + nginx gateway
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh

# Step 3 — verify
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

| URL | Purpose |
|-----|---------|
| http://127.0.0.1:8090/app/ | Mobile web (employee app) |
| http://127.0.0.1:8090/login | Admin console |
| http://127.0.0.1:8090/auth/api/v1/docs | Swagger (auth) |
| http://127.0.0.1:8081 | Admin direct (optional; prefer gateway) |

**Admin login:** `admin@orange.com` / `admin123` → OTP (auto in demo mode)

**Mobile login:** `demo@orange.com` → OTP → accept Terms & Conditions

**Reset demo data** before team testing:

```bash
./scripts/reset-demo-data.sh
```

**Stop everything:**

```bash
./scripts/stop-demo-server.sh
docker stop myboss-api-gateway 2>/dev/null || true
```

---

## 3. Run locally — each project separately

Use this when you are developing one app and want hot reload.

### Backend only (Node, no Docker)

```bash
cd myboss-backend
npm install
npm run build -w @myboss/common
npm run start:dev          # all 5 services on :3001–3005
```

Verify: `./scripts/verify-backend.sh` from **myboss-platform**, or:

```bash
curl http://localhost:3001/api/v1/health
```

Details: [myboss-backend/README.md](myboss-backend/README.md)

### Admin only (Vite dev server)

Start backend first (Docker or npm above), then:

```bash
cd myboss-admin
npm install
cp .env.example .env.development   # if not done yet
npm run dev
```

Open: http://localhost:5173

Details: [myboss-admin/README.md](myboss-admin/README.md)

### Mobile only (Flutter)

Start backend/gateway first, then:

```bash
cd myboss-mobile
fvm install 3.35.7    # first time only
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
```

**Web dev** (hot reload on :8092, API via gateway :8090):

```bash
./run-local-web.sh
```

**Android emulator** (backend on host):

```bash
fvm flutter run --dart-define=DEMO_MODE=true --dart-define=GATEWAY_ORIGIN=http://10.0.2.2:8090
```

Details: [myboss-mobile/README.md](myboss-mobile/README.md)

---

## 4. Deploy live (demo server / event)

For a VM (Ubuntu 22.04+, 4 vCPU, 8 GB RAM recommended):

### One-time server setup

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Log out and back in

# Clone all four repos as siblings
sudo mkdir -p /opt/myboss && cd /opt/myboss
sudo git clone https://github.com/areejobaid17894-blip/myboss-backend.git
sudo git clone https://github.com/areejobaid17894-blip/myboss-admin.git
sudo git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
sudo git clone https://github.com/areejobaid17894-blip/myboss-platform.git
sudo chown -R $USER:$USER /opt/myboss
```

Or use the helper script:

```bash
cd myboss-platform
./scripts/install-demo-server.sh /opt/myboss
```

### Configure & deploy

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
nano .env   # set JWT_SECRET, INTERNAL_SERVICE_TOKEN, DEMO_HOST=<server-public-ip>

chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh <SERVER_IP>
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh <SERVER_IP> --gateway
```

### Public URL (Cloudflare quick tunnel)

```bash
./scripts/start-demo-tunnel.sh
# URL saved to demo-public-url.txt (not in git)
```

Share with testers:
- Mobile: `https://<tunnel>/app/`
- Admin: `https://<tunnel>/login`

**Error 1033?** Tunnel stopped — restart script and use the new URL. See [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md).

### External Android APK (mobile data)

```bash
cd myboss-mobile
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk (email to testers)
```

### Demo vs production gateway

| Demo | Production |
|------|------------|
| nginx `:8090` | **Orange Apigee** |
| Same API paths | Same API paths |

Read: [`architecture/APIGEE_VS_NGINX.md`](architecture/APIGEE_VS_NGINX.md)

Full production guide: [`devops/DEVOPS.md`](devops/DEVOPS.md)

---

## 5. Demo test accounts

OTP auto-fills when `DEMO_MODE=true`.

| Email | Role / scenario |
|-------|-----------------|
| `demo@orange.com` | Employee — full flow, squad member |
| `nisreen.a@orange.com` | Squad leader |
| `omar.t@orange.com` | No squad — gating tests |
| `laila.m@orange.com` | Incomplete onboarding |
| `admin@orange.com` | Admin console |

After OTP on mobile: **Terms & conditions** must be accepted.

---

## 6. Override sibling paths

If repos are not siblings, export before running platform scripts:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## 7. Documentation index

| Doc | Location |
|-----|----------|
| Full docs index | [myboss-platform/docs/README.md](myboss-platform/docs/README.md) |
| DevOps / deploy | [myboss-platform/docs/devops/DEVOPS.md](myboss-platform/docs/devops/DEVOPS.md) |
| Database & seed | [myboss-platform/docs/database/DATABASE.md](myboss-platform/docs/database/DATABASE.md) |
| Android Studio | [myboss-platform/docs/mobile/ANDROID_STUDIO.md](myboss-platform/docs/mobile/ANDROID_STUDIO.md) |

Per-app READMEs: [myboss-backend](myboss-backend/README.md) · [myboss-admin](myboss-admin/README.md) · [myboss-mobile](myboss-mobile/README.md) · [myboss-platform](myboss-platform/README.md)
