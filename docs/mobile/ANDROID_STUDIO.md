# Mobile App — Android Studio Guide

**Audience:** Mobile developers, QA  
**App:** Flutter employee app (`myboss-mobile`)  
**Stack:** Flutter **3.35.7**, Dart **3.9.2+**, BLoC, Clean Architecture

Full feature coverage: [`../EMPLOYEE_JOURNEY_COVERAGE.md`](../EMPLOYEE_JOURNEY_COVERAGE.md)

---

## 1. Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **Android Studio** | Latest stable | [developer.android.com/studio](https://developer.android.com/studio) |
| **Flutter** | **3.35.7** | [FVM](https://fvm.app) — see `myboss-mobile/.fvmrc` |
| **Dart** | **≥3.9.2** | Bundled with Flutter |
| **Backend** | Running | See [`../devops/DEVOPS.md`](../devops/DEVOPS.md) |

Verify setup:

```bash
fvm flutter doctor
fvm flutter --version   # should show 3.35.7
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

## 4. Start backend (required)

### Option A — Docker demo (recommended for QA)

```bash
cd myboss-platform
cp .env.example .env
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

Gateway health: `curl http://127.0.0.1:8090/health`

### Option B — Local dev (no Docker)

```bash
cd myboss-backend
npm install
npm run start:dev
```

Services on ports **3001–3005**.

---

## 5. Run the app

### Terminal

```bash
cd myboss-mobile
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
```

### Android Studio

1. Open `lib/main.dart`
2. **Run → Edit Configurations**
3. Add to **Additional run args:** `--dart-define=DEMO_MODE=true`
4. Click green **Run ▶**

---

## 6. API connection modes

| Mode | Command | Backend path |
|------|---------|--------------|
| **Demo** (recommended) | `--dart-define=DEMO_MODE=true` | Gateway `:8090` (auto-probed at startup) |
| **Dev emulator** | `--dart-define=ENV=development` | Direct ports via `10.0.2.2:3001–3005` |
| **Dev physical device** | `--dart-define=API_HOST=<lan-ip>` | Direct ports on LAN IP |

When `DEMO_MODE=true`, the app probes hosts and picks the first reachable `/health`:

1. `GATEWAY_ORIGIN`
2. `API_HOSTS` (comma-separated)
3. `API_HOST`
4. Default from `demo_server_host.dart`

**Emulator with local gateway:**

```bash
fvm flutter run \
  --dart-define=DEMO_MODE=true \
  --dart-define=GATEWAY_ORIGIN=http://10.0.2.2:8090
```

Configuration files: `lib/core/config/` (`env_config.dart`, `demo_api_endpoints.dart`, `demo_server_host.dart`).

---

## 7. Physical Android device

### Demo APK (recommended for QA / field test)

```bash
cd myboss-mobile
./build-local-android.sh
# Output: build/android-dist/myboss-demo-<lan-ip>.apk
```

1. Copy APK to phone
2. **Uninstall** old app first
3. Install APK
4. Phone and Mac on same Wi‑Fi **or** Cloudflare tunnel running
5. Demo gateway on port **8090**

### Development run (direct microservice ports)

```bash
# Find Mac LAN IP
ipconfig getifaddr en0

fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=API_HOST=<lan-ip>
```

Allow firewall access to ports **3001–3005** (dev) or **8090** (demo).

---

## 8. Build scripts

| Script | Output |
|--------|--------|
| `build-local-android.sh` | Release APK → `build/android-dist/myboss-demo-*.apk` |
| `build-demo-apk.sh` | Release APK (tunnel + demo host) |
| `build-demo-web.sh` | Web build for gateway `/app/` |
| `run-local-web.sh` | Local dev web at `:8092` |
| `run-android-emulator.sh` | Emulator with demo gateway |
| `build-demo-ios.sh` | iOS demo build (macOS only) |

Deploy mobile web to gateway:

```bash
ALLOW_DEPLOY=1 ../../scripts/deploy-mobile-web.sh
```

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
| OTP | Auto-filled when `DEMO_MODE=true` |

---

## 10. Features (mobile)

| Feature | Notes |
|---------|-------|
| Auth | Email + OTP |
| Onboarding | Vest + building; skips if profile complete |
| Squad | Browse all + governorate filter; hub when no squad |
| Live chat | FAB on all tabs; **squad members only** — [`../api/CHAT_API.md`](../api/CHAT_API.md) |
| Gallery | Upload when in squad; admin announcement cards |
| Surveys | Dynamic segments; blocked without squad |
| Reports | Squad members only |
| Notifications | In-app inbox (demo — no OS push yet) |

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
| Network error on login | Backend not running — `curl http://127.0.0.1:8090/health` |
| Emulator cannot reach API | Use `GATEWAY_ORIGIN=http://10.0.2.2:8090` with `DEMO_MODE=true` |
| Physical device fails | Same Wi‑Fi; test `http://<mac-ip>:8090/health` in phone browser |
| Old APK still fails | Uninstall app before installing new APK |
| Gradle sync failed | File → Invalidate Caches; `fvm flutter clean && fvm flutter pub get` |
| OTP not received | Check auth logs for `[DEMO OTP]`; use demo build with auto-fill |
| Vertical text / empty squad cards | Use latest build; see squad list RTL fixes |

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Deploy backend & gateway |
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | REST endpoints |
| [`../deployment/pdf/04_TESTING_GUIDE.md`](../deployment/pdf/04_TESTING_GUIDE.md) | QA checklist |
| [`../../myboss-mobile/README.md`](../../myboss-mobile/README.md) | Quick reference |

---

*Orange — my boss app — Mobile*
