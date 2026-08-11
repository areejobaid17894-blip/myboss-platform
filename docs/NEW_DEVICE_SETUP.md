# New device setup — run my boss app end to end

Clone four repos, configure `.env`, start Docker, connect clients to **direct microservice ports** `:3001–3006`. No Apigee. No nginx gateway.

**URL reference:** [`deployment/SERVICE_URLS.md`](deployment/SERVICE_URLS.md)

---

## Quick path

| Goal | Steps | Time |
|------|-------|------|
| Admin in browser | §1–§4 → open `:8081` or `npm run dev` | ~15 min |
| Flutter emulator | Above + §5 | +5 min |
| APK on phone | Above + §6 | +10 min |

---

## 1. Install tools

Git · Docker Desktop 24+ · Node.js 20 LTS · Flutter 3.35.7 (FVM) · Android Studio (mobile)

---

## 2. Clone repos

```bash
mkdir -p ~/myboss-repos && cd ~/myboss-repos
git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
```

---

## 3. Configure `.env`

```bash
cd ~/myboss-repos/myboss-platform
cp .env.example .env
chmod +x scripts/*.sh
```

Set `JWT_SECRET`, `INTERNAL_SERVICE_TOKEN`, `DEMO_ADMIN_PASSWORD=admin123`.

---

## 4. Deploy

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

| App | Local URL |
|-----|-----------|
| Admin (Docker) | http://127.0.0.1:8081 |
| Admin (Vite) | http://127.0.0.1:5173 — `cd ../myboss-admin && npm run dev` |
| Auth Swagger | http://127.0.0.1:3001/api/v1/docs |

**Deployed server:** use your VM/LAN IP instead of `127.0.0.1` — see [`SERVICE_URLS.md`](deployment/SERVICE_URLS.md).

---

## 5. Mobile — emulator

```bash
cd ~/myboss-repos/myboss-mobile
fvm use 3.35.7 && fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

---

## 6. Mobile — physical device / remote server

```bash
# Same Wi‑Fi — replace with server LAN IP
fvm flutter run --dart-define=API_HOST=192.168.1.9 --dart-define=ENV=demo --dart-define=DEMO_MODE=true

# Or build APK
SERVER_HOST=192.168.1.9 ./build-external-android.sh
```

---

## Logins

Admin: `admin@orange.com` / `admin123` · Mobile: `demo@orange.com` (OTP auto-fills in demo)

---

*Orange — my boss app*
