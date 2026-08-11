# New device setup — run my boss app end to end

Use this guide when you set up a **new laptop** or install the app on a **new phone/tablet**.

The product spans **four Git repos**. Clone them as siblings, configure platform `.env`, start Docker backend, and connect clients to **Orange Apigee** (or direct ports for local dev). There is **no local nginx API gateway**.

---

## Quick path (recommended)

| Goal | Steps | Time |
|------|-------|------|
| Browser demo (admin) | [§1–§3](#1-install-tools) → [§4 Start stack](#4-start-the-backend-stack) → admin `npm run dev` | ~15 min |
| Flutter on emulator | Above + [§5 Emulator](#5-run-on-android-emulator) | +5 min |
| APK on physical phone | Above + [§6 Physical device](#6-run-on-a-physical-android-device) | +10 min |

Detailed env reference: [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## 1. Install tools

| Tool | Version | Install |
|------|---------|---------|
| **Git** | Latest | [git-scm.com](https://git-scm.com/) |
| **Docker Desktop** | 24+ (Compose v2) | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Node.js** | **20 LTS** | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| **Flutter (FVM)** | **3.35.7** | `brew install fvm && fvm install 3.35.7` |
| **Android Studio** | Latest | [developer.android.com/studio](https://developer.android.com/studio) |

Verify:

```bash
git --version
docker compose version
node --version    # v20.x
fvm flutter doctor
```

---

## 2. Clone all four repos

```bash
mkdir -p ~/myboss-repos && cd ~/myboss-repos

git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

Expected layout:

```
myboss-repos/
├── myboss-backend/
├── myboss-admin/
├── myboss-mobile/
└── myboss-platform/
```

**Clone fails?** See [`MULTI_REPO_SETUP.md`](MULTI_REPO_SETUP.md#clone-troubleshooting).

---

## 3. Configure environment

Only **`myboss-platform/.env`** is required for the Docker demo.

### 3.1 Platform (required)

```bash
cd ~/myboss-repos/myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Edit `.env` and set at minimum:

```bash
JWT_SECRET=<paste output of: openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<paste output of: openssl rand -base64 32>
DEMO_ADMIN_PASSWORD=admin123
```

Leave `DB_ENABLED=false` for the default in-memory demo. For MariaDB see [`database/DATABASE.md`](database/DATABASE.md).

### 3.2 Admin (Vite dev — recommended for local testing)

```bash
cd ~/myboss-repos/myboss-admin
cp .env.example .env.development
npm install
```

### 3.3 Backend (optional — npm dev without Docker)

```bash
cd ~/myboss-repos/myboss-backend
cp .env.example .env
# Use the SAME JWT_SECRET and INTERNAL_SERVICE_TOKEN as myboss-platform/.env
npm install
```

### 3.4 Mobile

No `.env` file. Pass config at build/run via `--dart-define`.

Future CI/CD: values move to **GitLab CI/CD variables** — [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md).

---

## 4. Start the backend stack

From `myboss-platform`:

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
```

First Docker build can take 2–5 minutes.

| What | URL |
|------|-----|
| Admin (Vite dev) | http://127.0.0.1:5173 — `cd ../myboss-admin && npm run dev` |
| Admin (Docker) | http://127.0.0.1:8081 (calls Apigee) |
| Apigee APIs | https://api-demo.orange.com/auth/api/v1/... |
| Auth Swagger (local) | http://127.0.0.1:3001/api/v1/docs |

**Admin login:** `admin@orange.com` / `admin123` → OTP (auto-fills in demo)

**Mobile login:** `demo@orange.com` → OTP → accept Terms & Conditions

Reset demo data:

```bash
./scripts/reset-demo-data.sh
```

Stop:

```bash
./scripts/stop-demo-server.sh
```

---

## 5. Run on Android emulator

**Option A — Apigee (recommended when proxies are live):**

```bash
cd ~/myboss-repos/myboss-mobile
fvm use 3.35.7
fvm flutter pub get
fvm flutter gen-l10n

fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

**Option B — Local backend (Docker running on same machine):**

```bash
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
# Emulator uses 10.0.2.2 for host machine ports :3001–3006
```

More detail: [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md)

---

## 6. Run on a physical Android device

### Option A — Apigee APK (testers anywhere)

```bash
cd ~/myboss-repos/myboss-mobile
./build-apigee-android.sh
# → build/android-dist/myboss-apigee-api-demo.orange.com.apk
```

Copy APK to phone and install. Allow **Install unknown apps** if prompted.

### Option B — USB debugging + local backend (same Wi‑Fi)

1. Enable **USB debugging** on the phone.
2. Connect USB; verify with `adb devices`.
3. Find your Mac LAN IP: `ipconfig getifaddr en0`

```bash
cd ~/myboss-repos/myboss-mobile
fvm flutter run \
  --dart-define=DEMO_MODE=true \
  --dart-define=ENV=development \
  --dart-define=API_HOST=192.168.1.9
```

Replace `192.168.1.9` with your IP. Phone must be on the same Wi‑Fi.

### Option C — LAN APK (no USB after install)

```bash
cd ~/myboss-repos/myboss-mobile
./build-local-android.sh
# → build/android-dist/myboss-demo-<ip>.apk
adb install -r build/android-dist/myboss-demo-*.apk
```

---

## 7. Run on iOS (simulator or device)

**Simulator (Mac with Xcode):**

```bash
cd ~/myboss-repos/myboss-mobile
fvm flutter run \
  --dart-define=DEMO_MODE=true \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo
```

**Physical iPhone:** `./build-ios-demo.sh` or Xcode. Push requires Firebase/APNs — see `myboss-mobile/ios/Runner/IOS_PUSH_SETUP.md`.

---

## 8. Demo test accounts

OTP auto-fills when `DEMO_MODE=true`.

| Email | Scenario |
|-------|----------|
| `demo@orange.com` | Employee — full flow, squad member |
| `nisreen.a@orange.com` | Squad leader |
| `omar.t@orange.com` | No squad — gating tests |
| `laila.m@orange.com` | Incomplete onboarding |
| `admin@orange.com` | Admin console |

---

## 9. Troubleshooting

| Problem | Fix |
|---------|-----|
| Admin login fails | `./scripts/fix-admin-login.sh` |
| APIs down after first build | Wait 30s; run `./scripts/verify-backend.sh` |
| Phone cannot reach local API | Same Wi‑Fi; use correct LAN IP; disable VPN |
| Emulator cannot reach API | Use `ENV=development` (uses `10.0.2.2`) |
| Apigee unreachable | Use local dev: admin `npm run dev`, mobile `ENV=development` |
| Flutter / Gradle errors | `fvm flutter clean && fvm flutter pub get` |
| Docker out of disk | `docker system prune` |

---

## 10. Related docs

| Topic | Document |
|-------|----------|
| DevOps deploy on VM | [`devops/DEVOPS.md`](devops/DEVOPS.md) |
| All env variables + GitLab | [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md) |
| Apigee wiring | [`deployment/APIGEE_CONNECTION.md`](deployment/APIGEE_CONNECTION.md) |
| QA smoke tests | [`deployment/TESTING.md`](deployment/TESTING.md) |
| Android Studio details | [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) |

---

*Orange — my boss app*
