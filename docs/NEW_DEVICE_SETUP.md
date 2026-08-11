# New device setup — run my boss app end to end

Use this guide when you set up a **new laptop** or install the app on a **new phone/tablet**.

The product spans **four Git repos**. Clone them as siblings, configure platform `.env`, start Docker backend, and connect clients to **Orange Apigee** (or direct ports for local dev). There is **no local nginx gateway**.

---

## Quick path (recommended)

| Goal | Steps | Time |
|------|-------|------|
| Browser demo (admin) | [§1–§3](#1-install-tools) → [§4 Start stack](#4-start-the-backend-stack) → admin `npm run dev` or `:8081` | ~15 min |
| Flutter on emulator | Above + [§5 Emulator](#5-run-on-android-emulator) | +5 min |
| APK on physical phone | Above + [§6 Physical device](#6-run-on-a-physical-android-device) | +10 min |

Detailed env reference: [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## 1. Install tools

Install on your **development machine** (Mac or Linux recommended; Windows works with WSL2 + Docker).

| Tool | Version | Install |
|------|---------|---------|
| **Git** | Latest | [git-scm.com](https://git-scm.com/) |
| **Docker Desktop** | 24+ (Compose v2) | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Node.js** | **20 LTS** | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| **Flutter (FVM)** | **3.35.7** | `brew install fvm && fvm install 3.35.7` |
| **Android Studio** | Latest | For emulator + USB debugging — [developer.android.com/studio](https://developer.android.com/studio) |
| **cloudflared** | Optional | `brew install cloudflared` — public URL for remote testers |

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

**Clone fails?** See troubleshooting in [`MULTI_REPO_SETUP.md`](MULTI_REPO_SETUP.md#clone-troubleshooting).

---

## 3. Configure environment

Only **`myboss-platform/.env`** is required for the Docker demo. Other `.env` files are for optional local dev without Docker.

### 3.1 Platform (required)

```bash
cd ~/myboss-repos/myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Edit `.env` and set at minimum:

```bash
# Generate once — keep the same values if you also run backend via npm
JWT_SECRET=<paste output of: openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<paste output of: openssl rand -base64 32>
DEMO_ADMIN_PASSWORD=admin123
```

Leave `DB_ENABLED=false` for the default in-memory demo. For MariaDB persistence see [`database/DATABASE.md`](database/DATABASE.md).

### 3.2 Admin (optional — Vite hot reload only)

Only if you run the admin UI on `:5173` instead of the Docker gateway:

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

No `.env` file. Configuration is passed at build/run time via `--dart-define` (see §5–§6).

**Never commit** `.env`, `.env.development`, or secret JSON files. Templates stay in git as `.env.example`.

Future CI/CD: these values will move to **GitLab CI/CD variables** — see [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md).

---

## 4. Start the backend stack

From `myboss-platform`:

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

First Docker build can take 2–5 minutes. Services listen on **direct ports** `:3001–3006` (no nginx).

| What | URL |
|------|-----|
| Admin (Docker) | http://127.0.0.1:8081 |
| Admin (Vite dev) | http://127.0.0.1:5173 — `cd ../myboss-admin && npm run dev` |
| Apigee APIs | https://api-demo.orange.com/auth/api/v1/... |
| Auth Swagger (local) | http://127.0.0.1:3001/api/v1/docs |

**Admin login:** `admin@orange.com` / `admin123` → OTP (auto-fills in demo)

**Mobile login:** use Apigee — `demo@orange.com` → OTP → accept Terms & Conditions

Reset demo data before a team session:

```bash
./scripts/reset-demo-data.sh
```

Stop everything:

```bash
./scripts/stop-demo-server.sh
```

---

## 5. Run on Android emulator

**Option A — Apigee (recommended):**

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

**Option B — Local backend (direct ports, backend Docker running):**

```bash
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
# Emulator uses 10.0.2.2 for host machine ports :3001–3005
```

More detail: [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md)

---

## 6. Run on a physical Android device

Choose **one** path below.

### Option A — USB debugging (fastest for developers)

1. On the phone: **Settings → Developer options → USB debugging** (enable).
2. Connect USB; accept the debugging prompt on the phone.
3. Verify: `adb devices` shows your device.
4. Phone and Mac must reach the same backend:
   - **Same Wi‑Fi:** use your Mac LAN IP (e.g. `192.168.1.9`).
   - **Mac only:** gateway must listen on `0.0.0.0` (default demo deploy uses Docker published ports).

```bash
# Find Mac LAN IP
ipconfig getifaddr en0   # or en1

cd ~/myboss-repos/myboss-mobile
fvm flutter run \
  --dart-define=DEMO_MODE=true \
  --dart-define=GATEWAY_ORIGIN=http://192.168.1.9:8090
```

Replace `192.168.1.9` with your IP. Ensure the phone is on the same Wi‑Fi and can open `http://192.168.1.9:8090/health` in Chrome.

### Option B — Install release APK (testers, no USB)

**Same Wi‑Fi as the demo server:**

```bash
# Start stack on your Mac (§4)
cd ~/myboss-repos/myboss-mobile
./build-local-android.sh
# → build/android-dist/myboss-demo-<ip>.apk
```

Copy the APK to the phone (AirDrop, email, Drive) and install. Allow **Install unknown apps** if prompted.

Install via USB:

```bash
adb install -r build/android-dist/myboss-demo-*.apk
```

**Outside your Wi‑Fi (mobile data):**

```bash
cd ~/myboss-repos/myboss-platform
./scripts/start-demo-tunnel.sh
# URL written to demo-public-url.txt

cd ../myboss-mobile
./build-external-android.sh
# → build/android-dist/myboss-demo-external.apk
```

Share the APK + tunnel URL. Tunnel details: [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md)

### Option C — Mobile web in phone browser

No install — open the gateway URL on the phone:

- Same Wi‑Fi: `http://<mac-lan-ip>:8090/app/`
- Public tunnel: `https://<tunnel-url>/app/`

---

## 7. Run on iOS (simulator or device)

**Simulator (Mac with Xcode):**

```bash
cd ~/myboss-repos/myboss-mobile
fvm flutter run \
  --dart-define=DEMO_MODE=true \
  --dart-define=GATEWAY_ORIGIN=http://127.0.0.1:8090
```

**Physical iPhone:** use `./build-ios-demo.sh` or Xcode; push requires extra Firebase/APNs setup — see `myboss-mobile/ios/Runner/IOS_PUSH_SETUP.md`.

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
| Gateway 502 / APIs down | Wait 30s after first build; run `./scripts/verify-backend.sh` |
| Phone cannot reach API | Same Wi‑Fi; check `http://<ip>:8090/health`; disable VPN on phone |
| Emulator cannot reach API | Use `GATEWAY_ORIGIN=http://10.0.2.2:8090` |
| Tunnel Error 1033 | Restart `./scripts/start-demo-tunnel.sh`; share **new** URL |
| Flutter / Gradle errors | `fvm flutter clean && fvm flutter pub get` |
| Docker out of disk | `docker system prune` (removes unused images) |

---

## 10. Related docs

| Topic | Document |
|-------|----------|
| All environment variables + GitLab CI/CD | [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md) |
| Full multi-repo guide | [`MULTI_REPO_SETUP.md`](MULTI_REPO_SETUP.md) |
| Android Studio details | [`mobile/ANDROID_STUDIO.md`](mobile/ANDROID_STUDIO.md) |
| Tunnel + external APK | [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md) |
| Push notifications | [`PUSH_FIREBASE_SETUP.md`](PUSH_FIREBASE_SETUP.md) |

---

*Orange — my boss app*
