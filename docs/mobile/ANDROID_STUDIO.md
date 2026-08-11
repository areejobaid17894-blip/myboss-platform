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
./scripts/verify-mobile-api.sh 127.0.0.1
```

Health: `curl http://127.0.0.1:3001/api/v1/health`

### Option B — Local dev (no Docker)

```bash
cd myboss-backend
npm install && npm run start:dev
```

Services on ports **3001–3006**.

### Option C — Apigee only (no local backend)

Use when Apigee proxies are already wired to a remote VM.

---

## 5. Run the app

### Terminal — Apigee

```bash
cd myboss-mobile
fvm flutter pub get && fvm flutter gen-l10n
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

### Terminal — local Docker backend

```bash
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

### Android Studio

1. Open `lib/main.dart`
2. **Run → Edit Configurations**
3. Add to **Additional run args:** `--dart-define=DEMO_MODE=true`
4. Click green **Run ▶**

---

## 6. API connection modes

| Mode | Command | Backend |
|------|---------|---------|
| **Apigee demo** | `GATEWAY_ORIGIN=https://api-demo.orange.com` + `ENV=demo` | Orange Apigee |
| **Dev emulator** | `ENV=development` | Direct ports via `10.0.2.2:3001–3006` |
| **Dev physical device** | `ENV=development` + `GATEWAY_ORIGIN=http://<lan-ip>:3001` | LAN direct ports |

Configuration: `lib/core/config/env_config.dart`

**Emulator with local Docker:**

```bash
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true
```

---

## 7. Physical Android device

### Apigee APK (recommended — works on mobile data)

```bash
cd myboss-mobile
./build-apigee-android.sh
# → build/android-dist/myboss-apigee-api-demo.orange.com.apk
```

### LAN APK (same Wi‑Fi as demo server)

```bash
./build-local-android.sh
# → build/android-dist/myboss-demo-<lan-ip>.apk
```

### Development run (USB)

```bash
ipconfig getifaddr en0   # Mac LAN IP

fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=DEMO_MODE=true \
  --dart-define=GATEWAY_ORIGIN=http://<lan-ip>:3001
```

---

## 8. Build scripts

| Script | Output |
|--------|--------|
| `build-apigee-android.sh` | Apigee demo APK |
| `build-local-android.sh` | LAN APK |
| `build-external-android.sh` | Apigee APK |
| `run-local-web.sh` | Local dev web |
| `run-android-emulator.sh` | Emulator helper |
| `build-ios-demo.sh` | iOS demo build |

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
| Network error on login | Backend not running — `curl http://127.0.0.1:3001/api/v1/health` |
| Emulator cannot reach API | Use `ENV=development` (uses `10.0.2.2`) |
| Physical device fails | Same Wi‑Fi; correct LAN IP in `GATEWAY_ORIGIN` |
| Apigee unreachable | Use local dev mode or `./build-local-android.sh` |
| Old APK still fails | Uninstall app before installing new APK |
| Gradle sync failed | File → Invalidate Caches; `fvm flutter clean && fvm flutter pub get` |

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Deploy backend |
| [`../deployment/TESTING.md`](../deployment/TESTING.md) | QA checklist |
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | REST endpoints |
| [`../../myboss-mobile/README.md`](../../myboss-mobile/README.md) | Quick reference |

---

*Orange — my boss app — Mobile*
