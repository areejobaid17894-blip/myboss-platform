# my boss app — Local development guide

Four projects that work together as a single product. Keep them as **sibling folders** — platform scripts expect the others next door.

> **New machine or new phone?** Start with [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md).  
> **DevOps / VM deploy:** [`devops/DEVOPS.md`](devops/DEVOPS.md).  
> **Client URLs:** [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md)

```
myboss-repos/
├── myboss-mobile/      Flutter employee app
├── myboss-admin/       React admin portal
├── myboss-backend/     NestJS microservices (6 services)
└── myboss-platform/    Docs, Docker, deploy scripts
```

Clients call **microservices directly** on ports **3001–3006**. No Apigee. No nginx API gateway.

---

## Clone troubleshooting

| Error | Fix |
|-------|-----|
| `unable to read from remote repository` | Use **HTTPS** URLs (not `git@github.com:...`) |
| `Repository not found` | Use the four URLs in [`NEW_DEVICE_SETUP.md`](NEW_DEVICE_SETUP.md) |
| `Permission denied (publickey)` | HTTPS clone, or add SSH key to GitHub |
| Only cloned one repo | Clone **all four** for full demo |

```bash
mkdir -p ~/myboss-repos && cd ~/myboss-repos
git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

---

## Run the full demo stack

```bash
cd myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
```

| URL | Purpose |
|-----|---------|
| http://127.0.0.1:5173 | Admin (Vite — `cd ../myboss-admin && npm run dev`) |
| http://127.0.0.1:8081 | Admin (Docker — direct port APIs) |
| http://127.0.0.1:8092 | Employee web (Flutter — `./run-local-web.sh`) |
| http://127.0.0.1:3001/api/v1/docs | Auth Swagger |

Reset demo data: `./scripts/reset-demo-data.sh`  
Stop: `./scripts/stop-demo-server.sh`

---

## Run one project at a time

### Backend (Node hot reload)

```bash
cd myboss-backend
npm install && cp .env.example .env
npm run build -w @myboss/common
npm run start:dev
```

→ [backend README](https://github.com/areejobaid17894-blip/myboss-backend/blob/main/README.md)

### Admin (Vite)

```bash
cd myboss-admin
npm install && cp .env.example .env.development
npm run dev
```

Open http://127.0.0.1:5173 — APIs on `localhost:3001–3005`.

### Mobile (Flutter)

**Emulator / same machine:**

```bash
cd myboss-mobile
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

**LAN / deployed server:**

```bash
fvm flutter run --dart-define=API_HOST=<SERVER_IP> --dart-define=ENV=demo --dart-define=DEMO_MODE=true
SERVER_HOST=<SERVER_IP> ./build-external-android.sh
```

**Employee web (browser):**

```bash
./run-local-web.sh                                    # localhost only
fvm flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8092 \
  --dart-define=API_HOST=<SERVER_IP> --dart-define=ENV=demo --dart-define=DEMO_MODE=true
```

→ [mobile README](https://github.com/areejobaid17894-blip/myboss-mobile/blob/main/README.md)

---

## Demo server / VM deploy

```bash
cd myboss-platform
./scripts/install-demo-server.sh /opt/myboss
cd /opt/myboss/myboss-platform
cp .env.example .env
# Set JWT_SECRET, INTERNAL_SERVICE_TOKEN, DEMO_HOST=<lan-or-public-ip>
./scripts/deploy-demo-server.sh <SERVER_IP>
```

See [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md) for client URLs and firewall ports.

---

## What goes where

| Artifact | Location |
|----------|----------|
| Docker secrets | `myboss-platform/.env` |
| Backend dev secrets | `myboss-backend/.env` |
| Admin Vite config | `myboss-admin/.env.development` |
| Built APK | `myboss-mobile/build/android-dist/` |
| Documentation | `myboss-platform/docs/` |

---

## Custom folder layout

```bash
export MYBOSS_BACKEND_DIR=/path/to/myboss-backend
export MYBOSS_ADMIN_DIR=/path/to/myboss-admin
export MYBOSS_MOBILE_DIR=/path/to/myboss-mobile
```

---

## Documentation index

| Doc | Purpose |
|-----|---------|
| [NEW_DEVICE_SETUP.md](NEW_DEVICE_SETUP.md) | New laptop / phone |
| [devops/DEVOPS.md](devops/DEVOPS.md) | VM deploy & verify |
| [deployment/SERVICE_URLS.md](deployment/SERVICE_URLS.md) | Direct port URLs |
| [deployment/TESTING.md](deployment/TESTING.md) | QA checklist |
| [mobile/ANDROID_STUDIO.md](mobile/ANDROID_STUDIO.md) | Emulator & APK |

Per-app READMEs: [backend](../../myboss-backend/README.md) · [admin](../../myboss-admin/README.md) · [mobile](../../myboss-mobile/README.md) · [platform](../README.md)

---

*Orange — my boss app*
