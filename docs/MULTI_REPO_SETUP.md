# my boss app — Local development guide

Four projects that work together as a single product. Keep them as **sibling folders** on your machine — platform scripts expect to find the others next door.

```
myboss-repos/
├── myboss-mobile/      Flutter employee app
├── myboss-admin/       React admin portal
├── myboss-backend/     NestJS microservices (5 services)
└── myboss-platform/    Docs, Docker, deploy scripts, nginx gateway
```

Each project has its own README with deeper detail. This guide covers the full stack end to end.

> **Note:** Links to other repos use full GitHub URLs so they work when browsing a single repo on github.com. Shell commands like `cd ../myboss-platform` assume all four projects are cloned as **siblings** on your machine.

---

## New machine checklist

Follow this on a **fresh laptop or VM** to run the full demo (backend + admin + mobile web).

**1. Install**

| Tool | Version |
|------|---------|
| Node.js | 20 LTS |
| Docker Desktop | 24+ (Compose v2) |
| Flutter | 3.35.7 (only if building mobile web/APK) |

**2. Download the four projects**

The app is **four separate repos** — not one monorepo. Clone all four as **siblings** in one folder:

```bash
mkdir -p ~/myboss-repos && cd ~/myboss-repos

git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

You should end up with:

```
myboss-repos/
├── myboss-backend/
├── myboss-admin/
├── myboss-mobile/
└── myboss-platform/
```

**Clone troubleshooting**

| Error | Cause | Fix |
|-------|--------|-----|
| **`unable to read from remote repository`** | SSH clone without a GitHub SSH key, or bad saved credentials | Use **HTTPS** URLs below (not `git@github.com:...`). See fix steps below. |
| `Repository not found` | Wrong URL or old monorepo name (`my_boss_v5`) | Use the four URLs above exactly |
| `Permission denied (publickey)` | SSH without a GitHub key | Use **HTTPS** URLs above, or add an SSH key to GitHub |
| `git: command not found` | Git not installed | Install Git: [git-scm.com](https://git-scm.com/) |
| `Could not resolve host` | No internet / firewall | Check network; try in a browser: https://github.com/areejobaid17894-blip/myboss-platform |
| Only cloned one repo | Backend alone is not enough for full demo | Clone **all four** |

**Fix: "unable to read from remote repository"**

On the other device, run these in order:

```bash
# 1. Test GitHub is reachable
curl -I https://github.com

# 2. Clone with HTTPS (copy/paste exactly — do NOT use git@github.com)
mkdir -p ~/myboss-repos && cd ~/myboss-repos
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

If step 2 still fails:

```bash
# 3. Clear wrong saved GitHub credentials (macOS)
git credential-osxkeychain erase <<EOF
host=github.com
protocol=https
EOF

# Windows: Control Panel → Credential Manager → remove github.com entries
# Then retry the HTTPS clone
```

If HTTPS still fails, download ZIPs from the browser (no Git auth needed):

- https://github.com/areejobaid17894-blip/myboss-platform/archive/refs/heads/main.zip
- https://github.com/areejobaid17894-blip/myboss-backend/archive/refs/heads/main.zip
- https://github.com/areejobaid17894-blip/myboss-admin/archive/refs/heads/main.zip
- https://github.com/areejobaid17894-blip/myboss-mobile/archive/refs/heads/main.zip

Unzip all four into one folder and rename to `myboss-platform`, `myboss-backend`, etc. (remove the `-main` suffix).

Repos are **public** — no GitHub login required for HTTPS clone.

**3. Configure platform env** (required for Docker):

```bash
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Edit `.env` and set:

```bash
JWT_SECRET=$(openssl rand -base64 48)
INTERNAL_SERVICE_TOKEN=$(openssl rand -base64 32)
DEMO_ADMIN_PASSWORD=admin123
```

**Optional — persistent database:** Demo defaults to in-memory (`DB_ENABLED=false`). To use MariaDB with a **single shared database** for all microservices:

```bash
DB_ENABLED=true
MARIADB_DATABASE=myboss
```

Start with MariaDB profile: `docker compose -f docker/docker-compose.demo.yml --profile with-mariadb up -d --build`  
Schema details: [docs/database/DATABASE.md](database/DATABASE.md)

**4. Start the stack**

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

**5. Open in browser**

| App | URL |
|-----|-----|
| Admin | http://127.0.0.1:8090/login |
| Mobile web | http://127.0.0.1:8090/app/ |

**Admin:** `admin@orange.com` / `admin123` → OTP (auto in demo)

**6. Optional — public URL for remote testers**

```bash
./scripts/start-demo-tunnel.sh
# URL saved to demo-public-url.txt
```

**7. Optional — Android APK**

```bash
cd ../myboss-mobile
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk
```

**Troubleshooting**

| Problem | Fix |
|---------|-----|
| Admin login "Invalid email or password" | `./scripts/fix-admin-login.sh` |
| Tunnel Error 1033 / blank page | Restart `./scripts/start-demo-tunnel.sh`, use **new** URL |
| Backend only (no Docker) | See [backend README — Run on a new machine](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md#run-on-a-new-machine) Option B |

---

## What goes where

Runtime files belong **inside** the project that owns them — not in the parent folder.

| Artifact | Location |
|----------|----------|
| Docker secrets & config | `myboss-platform/.env` |
| Backend dev secrets | `myboss-backend/.env` |
| Admin Vite config | `myboss-admin/.env.development` |
| Tunnel public URL | `myboss-platform/demo-public-url.txt` |
| Tunnel logs | `myboss-platform/demo-tunnel.log` |
| Built APK | `myboss-mobile/build/android-dist/` |
| Setup documentation | `myboss-platform/docs/` |

---

## Install once

| Tool | Version | Install |
|------|---------|---------|
| **Node.js** | 20 LTS | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| **npm** | 10+ | Bundled with Node 20 |
| **Docker Desktop** | 24+ (Compose v2) | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Flutter** | 3.35.7 | [FVM](https://fvm.app): `brew install fvm && fvm install 3.35.7` |
| **Android Studio** | Latest | Emulator and APK builds |
| **cloudflared** | Optional | `brew install cloudflared` — public demo URL |

Place all four projects in one folder (e.g. `~/Desktop/myboss-repos/`).

---

## Environment setup

Before the first run, copy the example env files and generate secrets.

**Platform** (Docker deploy reads this):

```bash
cd myboss-platform
cp .env.example .env
```

**Backend** (only if you run services via npm, not Docker):

```bash
cd ../myboss-backend
cp .env.example .env
# Use the same JWT_SECRET and INTERNAL_SERVICE_TOKEN as platform
```

**Admin** (Vite dev server):

```bash
cd ../myboss-admin
cp .env.example .env.development
```

Generate secrets:

```bash
openssl rand -base64 48   # JWT_SECRET
openssl rand -base64 32   # INTERNAL_SERVICE_TOKEN
```

### Local files you'll create over time

**Platform**

| File | Required? | How |
|------|-----------|-----|
| `.env` | Yes | `cp .env.example .env` |
| `demo-public-url.txt` | Tunnel demos | `./scripts/start-demo-tunnel.sh` |
| `demo-tunnel.log`, `demo-tunnel*.pid` | Auto | Tunnel script |
| `docker/data/` | Auto | Postgres when Docker runs |

**Backend**

| File | Required? | How |
|------|-----------|-----|
| `.env` | npm dev only | `cp .env.example .env` |
| `node_modules/` | Yes | `npm install` |
| `dist/` folders | Build | `npm run build` |
| `services/survey-service/data/` | Auto | SQLite at runtime |

**Admin**

| File | Required? | How |
|------|-----------|-----|
| `.env.development` | Vite dev | `cp .env.example .env.development` |
| `node_modules/` | Yes | `npm install` |
| `dist/` | Build | `npm run build` |

**Mobile**

| File | Required? | How |
|------|-----------|-----|
| `.dart_tool/` | Yes | `fvm flutter pub get` |
| `lib/gen/` | Yes | `fvm flutter gen-l10n` |
| `build/` | Build | APK or web scripts |
| `demo-public-url.txt` | External APK | From platform tunnel |
| `android/local.properties` | Android | Android Studio |

Per-project READMEs: [backend](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md) · [admin](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md) · [mobile](https://github.com/areejobaid17894-blip/myboss-mobile/blob/main/README.md) · [platform](https://github.com/areejobaid17894-blip/myboss-platform/blob/main/README.md)

---

## Run the full demo stack

Starts backend + admin in Docker, builds mobile web, serves everything on **port 8090**. This is what you want for integration testing or showing the product.

```bash
cd myboss-platform
chmod +x scripts/*.sh

./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh

./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

| URL | Purpose |
|-----|---------|
| http://127.0.0.1:8090/app/ | Mobile web |
| http://127.0.0.1:8090/login | Admin console |
| http://127.0.0.1:8090/auth/api/v1/docs | Swagger (auth) |

**Admin:** `admin@orange.com` / `admin123` → OTP (auto in demo mode)

**Mobile:** `demo@orange.com` → OTP → accept Terms & Conditions

Reset demo data before a team session:

```bash
./scripts/reset-demo-data.sh
```

Stop everything:

```bash
./scripts/stop-demo-server.sh
docker stop myboss-api-gateway 2>/dev/null || true
```

---

## Run one project at a time

Use this when you're developing a single app with hot reload.

### Backend (Node)

```bash
cd myboss-backend
npm install
npm run build -w @myboss/common
npm run start:dev
```

Health check: `curl http://localhost:3001/api/v1/health`

→ [backend README](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md)

### Admin (Vite)

Start backend first, then:

```bash
cd myboss-admin
npm install
cp .env.example .env.development
npm run dev
```

Open http://localhost:5173

→ [admin README](https://github.com/areejobaid17894-blip/myboss-admin/blob/main/README.md)

### Mobile (Flutter)

Start backend/gateway first, then:

```bash
cd myboss-mobile
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
```

Web hot reload: `./run-local-web.sh` (gateway must be on :8090)

Android emulator: add `--dart-define=GATEWAY_ORIGIN=http://10.0.2.2:8090`

→ [mobile README](https://github.com/areejobaid17894-blip/myboss-mobile/blob/main/README.md)

---

## Demo server / event deploy

Target: Ubuntu 22.04+, 4 vCPU, 8 GB RAM, Docker installed.

**One-time setup:**

```bash
cd myboss-platform
./scripts/install-demo-server.sh /opt/myboss
```

Places all four projects under `/opt/myboss/`.

**Deploy:**

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
# JWT_SECRET, INTERNAL_SERVICE_TOKEN, DEMO_HOST=<public-ip>

chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh <SERVER_IP>
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh <SERVER_IP> --gateway
```

### Public URL (Cloudflare quick tunnel)

```bash
./scripts/start-demo-tunnel.sh
```

URL saved to `demo-public-url.txt`. Share:

- Mobile: `https://<tunnel>/app/`
- Admin: `https://<tunnel>/login`

**Error 1033?** The tunnel process stopped — restart the script and share the new URL. See [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md).

### External Android APK

```bash
cd myboss-mobile
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk
```

### Demo vs production gateway

| Demo | Production |
|------|------------|
| nginx `:8090` | Orange **Apigee** |
| Same API paths | Same API paths |

→ [`architecture/APIGEE_VS_NGINX.md`](architecture/APIGEE_VS_NGINX.md)  
→ Production: [`devops/DEVOPS.md`](devops/DEVOPS.md)

---

## Demo test accounts

OTP auto-fills when `DEMO_MODE=true`.

| Email | Role / scenario |
|-------|-----------------|
| `demo@orange.com` | Employee — full flow, squad member |
| `nisreen.a@orange.com` | Squad leader |
| `omar.t@orange.com` | No squad — gating tests |
| `laila.m@orange.com` | Incomplete onboarding |
| `admin@orange.com` | Admin console |

Mobile users must accept Terms & conditions after OTP.

---

## Custom folder layout

If the four projects aren't siblings, tell platform scripts where to look:

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## Documentation index

| Doc | Location |
|-----|----------|
| Docs index | [docs/README.md](README.md) |
| DevOps / deploy | [docs/devops/DEVOPS.md](devops/DEVOPS.md) |
| Database & seed | [docs/database/DATABASE.md](database/DATABASE.md) |
| Android Studio | [docs/mobile/ANDROID_STUDIO.md](mobile/ANDROID_STUDIO.md) |
| Tunnel + APK | [docs/deployment/DEMO_TUNNEL_AND_APK.md](deployment/DEMO_TUNNEL_AND_APK.md) |
| Apigee vs nginx | [docs/architecture/APIGEE_VS_NGINX.md](architecture/APIGEE_VS_NGINX.md) |

Per-app READMEs: [backend](../../myboss-backend/README.md) · [admin](../../myboss-admin/README.md) · [mobile](../../myboss-mobile/README.md) · [platform](../README.md)
