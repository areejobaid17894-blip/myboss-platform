# Mobile App — Android Studio Guide

**Audience:** Mobile developers, QA  
**App:** Flutter employee app (`myboss-mobile`)  
**Stack:** Flutter **3.35.7**, Dart **3.9.2+**, BLoC, Clean Architecture

Backend: **single API on :3001**. See [`../INSTALL.md`](../INSTALL.md).

## Flutter runs independently

| Layer | How it runs |
|-------|-------------|
| Backend APIs | Docker (`myboss-platform`) |
| Employee Flutter app | **Local only** — Android Studio / `flutter run`. **Not** a Docker Compose service |

---

## 1. Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **Android Studio** | Latest stable | [developer.android.com/studio](https://developer.android.com/studio) |
| **Flutter** | **3.35.7** | [FVM](https://fvm.app) — see `myboss-mobile/.fvmrc` — or a local 3.35.7 install on `PATH` |
| **Dart** | **≥3.9.2** | Bundled with Flutter |
| **Backend** | Running in Docker | See [`../INSTALL.md`](../INSTALL.md) / [`../devops/DEVOPS.md`](../devops/DEVOPS.md) |

Verify setup:

```bash
fvm flutter doctor
fvm flutter --version   # should show 3.35.7
# Windows without FVM: flutter --version
```

---

## 2. Open project in Android Studio

1. Launch **Android Studio**
2. **File → Open**
3. Select folder: `myboss-mobile`
4. Wait for Gradle sync to finish
5. If prompted: **Trust Project**

Project structure:

```
myboss-mobile/lib/
├── app/           # App widget, theme, main shell
├── core/          # DI, network, session, router
└── features/      # auth, squad, survey, gallery, chat, profile, …
```

---

## 3. Android emulator setup

1. **Tools → Device Manager**
2. Create device (if none): **Pixel 6**, **API 34** recommended
3. Click **▶ Play** to start emulator
4. Select the emulator as run target in the toolbar

---

## 4. Start backend first (Docker — required)

Flutter does **not** start APIs.

### Option A — Docker demo (recommended)

```bash
cd myboss-platform
cp .env.example .env
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

Health: `curl http://127.0.0.1:3001/api/v1/health`

### Option B — Local Nest (no Docker)

```bash
cd myboss-backend
npm install && npm run start:dev
```

Single API on **:3001**.

### Option C — Apigee only (no local backend)

Use when Apigee proxies are already wired to a remote VM.

---

## 5. Run the Flutter app (separate process)

Confirm backend first: `curl http://127.0.0.1:3001/api/v1/health`

### Web (Windows) — independent of Docker

```powershell
cd myboss-mobile
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8092 `
  --dart-define=ENV=development --dart-define=API_HOST=localhost --dart-define=DEMO_MODE=false
# → http://127.0.0.1:8092
```

Stop with `q` in that terminal. Docker APIs keep running.

### Android emulator

```bash
cd myboss-mobile
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=API_HOST=10.0.2.2 \
  --dart-define=DEMO_MODE=false
```

### Android Studio

1. Open `lib/main.dart`
2. **Run → Edit Configurations**
3. **Additional run args:**  
   `--dart-define=ENV=development --dart-define=API_HOST=10.0.2.2 --dart-define=DEMO_MODE=false`
4. Click green **Run ▶**

---

## 6. API connection modes

| Mode | dart-defines | Host used |
|------|--------------|-----------|
| **Web on same PC** | `ENV=development` `API_HOST=localhost` | `localhost:3001` |
| **Android emulator** | `ENV=development` `API_HOST=10.0.2.2` | Host machine via `10.0.2.2` |
| **Physical device (Wi‑Fi)** | `ENV=development` `API_HOST=<LAN-IP>` | Your PC LAN IP |
| **Physical device (cellular)** | `ENV=development` `API_HOST=<public-IP>` | Host public IP; firewall/router must publish **3001** |
| **Apigee (optional)** | build scripts / gateway builds | Orange Apigee |

Configuration: `lib/core/config/env_config.dart` + `dev_api_host.dart`

---

## 7. Physical Android device

### LAN APK (same Wi‑Fi as your PC / demo server)

```bash
flutter build apk --release \
  --dart-define=ENV=development \
  --dart-define=API_HOST=<your-lan-ip> \
  --dart-define=API_PORT=3001 \
  --dart-define=DEMO_MODE=false \
  --dart-define=PUSH_ENABLED=true
```

### Development run (USB)

```bash
# Windows: ipconfig → IPv4 address
# Mac: ipconfig getifaddr en0

fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=API_HOST=<lan-ip> \
  --dart-define=DEMO_MODE=false
```

### Cellular APK (only if `:3001` is published on a public IP)

```bash
flutter build apk --release \
  --dart-define=ENV=development \
  --dart-define=API_HOST=<public-ip> \
  --dart-define=API_PORT=3001 \
  --dart-define=DEMO_MODE=false
```

---

## 8. Release APK

```bash
cd myboss-mobile
flutter build apk --release \
  --dart-define=ENV=development \
  --dart-define=API_HOST=<host> \
  --dart-define=API_PORT=3001 \
  --dart-define=DEMO_MODE=false \
  --dart-define=PUSH_ENABLED=true
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 9. Demo login & test accounts

| Email | Squad | Use case |
|-------|-------|----------|
| `demo@orange.com` | Orange Amman | Full happy path |
| `omar.t@orange.com` | None | Squad gating (chat, surveys, gallery locked) |
| `nisreen.a@orange.com` | Leader | Squad leader flows |
| `laila.m@orange.com` | None | Onboarding |

| Field | Value |
|-------|-------|
| OTP | Emailed via Orange Maxit (`DEMO_MODE=false` — no auto-fill) |

---

## 10. Features (mobile)

| Feature | Notes |
|---------|-------|
| Auth | Email + OTP |
| Onboarding | Vest + building; skips if profile complete |
| Squad | Browse all + governorate filter; hub when no squad |
| Live chat | FAB on all tabs; **squad members only** — [`../api/CHAT_API.md`](../api/CHAT_API.md) |
| Gallery | Upload when in squad; admin announcement cards |
| Surveys | Dynamic segments; blocked without squad. Cached on Home (online) so they can be opened and filled **offline**; close saves a draft. See [`OFFLINE_SURVEYS.md`](OFFLINE_SURVEYS.md) |
| Reports | Squad members only |
| Notifications | In-app inbox + FCM when `PUSH_ENABLED=true` and the API has a live Firebase key |

---

## 11. Localization & tests

```bash
fvm flutter gen-l10n          # ARB files in l10n/
fvm flutter test
fvm flutter analyze
```

---

## 12. Troubleshooting

| Problem | Fix |
|---------|-----|
| Network error on login | Backend not running — `curl http://127.0.0.1:3001/api/v1/health` |
| Looking for Flutter in Docker | Flutter is **not** a Compose service — run Android Studio or `flutter run` locally |
| OTP returns to login | Update `myboss-mobile`; hard-refresh `:8092`. Wrong OTP should stay on OTP screen |
| Emulator cannot reach API | Use `ENV=development` (uses `10.0.2.2`) |
| Physical device fails | Same Wi‑Fi; correct LAN IP in `API_HOST` |
| API unreachable | Same Wi‑Fi; correct LAN IP in `API_HOST` |
| Old APK still fails | Uninstall app before installing new APK |
| Service will not open offline | Open Home **once online** after install so schemas cache. See [`OFFLINE_SURVEYS.md`](OFFLINE_SURVEYS.md) |
| Gradle sync failed | File → Invalidate Caches; `fvm flutter clean && fvm flutter pub get` |

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Deploy backend |
| [`../deployment/TESTING.md`](../deployment/TESTING.md) | QA checklist |
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | REST endpoints |
| [`OFFLINE_SURVEYS.md`](OFFLINE_SURVEYS.md) | Offline cache + draft QA |
| [`../../myboss-mobile/README.md`](../../myboss-mobile/README.md) | Quick reference |

---

*Orange — my boss app — Mobile*
