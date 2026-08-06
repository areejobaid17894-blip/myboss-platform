# Push notifications — Firebase setup

Firebase project: **`my-boss-app-38576`** (test project)

Console: https://console.firebase.google.com/project/my-boss-app-38576

---

## Architecture

```
Admin → POST /survey/api/v1/notifications
     → survey-service (in-app truth + gallery)
     → notification-service (FCM HTTP v1, port 3006)
     → user-service (device token lookup)
     → FCM → mobile PushService
```

In-app notifications work without FCM. Push requires backend FCM enabled **and** mobile built with `PUSH_ENABLED=true`.

---

## 1. Firebase project files

| File | Location | Status |
|------|----------|--------|
| `google-services.json` | `myboss-mobile/android/app/` | ✅ Configured |
| `firebase_options.dart` | `myboss-mobile/lib/` | ✅ Android configured |
| Service account JSON | `myboss-platform/secrets/fcm-service-account.json` | ✅ Required for backend |
| `GoogleService-Info.plist` | `myboss-mobile/ios/Runner/` | ⚠️ Add via `./scripts/setup-ios-firebase.sh` |
| APNs `.p8` key | Firebase Console → Cloud Messaging | ⚠️ Required for iOS push delivery |

**Never commit** `secrets/fcm-service-account.json` or service account keys to git.

---

## 2. Backend configuration

Add to **`myboss-platform/.env`** (Docker reads this file):

```env
FCM_ENABLED=true
FCM_PROJECT_ID=my-boss-app-38576
FCM_SERVICE_ACCOUNT_PATH=/run/secrets/fcm-service-account.json
FCM_SERVICE_ACCOUNT_HOST_PATH=/absolute/path/to/myboss-platform/secrets/fcm-service-account.json
NOTIFICATION_SERVICE_URL=http://notification-service:3006/api/v1
PUSH_DISPATCH_ENABLED=true
NOTIFICATION_SERVICE_PORT=3006
```

Place the downloaded Firebase Admin SDK JSON at:

```
myboss-platform/secrets/fcm-service-account.json
```

Redeploy:

```bash
cd myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

Expected:

```bash
curl http://127.0.0.1:8090/notification/api/v1/push/status
# {"fcmEnabled":true,"mode":"live"}
```

For **npm-only** backend dev, copy the same FCM vars to `myboss-backend/.env` and point `FCM_SERVICE_ACCOUNT_PATH` at the host file path directly.

---

## 3. Mobile configuration

Android is configured. Build with push enabled:

```bash
cd myboss-mobile
fvm flutter pub get
fvm flutter gen-l10n

# External testers (Cloudflare tunnel URL baked in):
./build-external-android.sh

# Same Wi‑Fi:
./build-local-android.sh
```

All APK build scripts pass `--dart-define=PUSH_ENABLED=true`.

### iOS push

Native iOS plumbing is in place (entitlements, AppDelegate, background modes). You still need Firebase + Apple credentials:

1. Register iOS app in Firebase — bundle ID **`com.myboss.mybossMobile`**
2. Download `GoogleService-Info.plist` → run `./scripts/setup-ios-firebase.sh`
3. Upload **APNs `.p8` key** to Firebase → Cloud Messaging
4. Run on device: `./build-ios-demo.sh`

Full guide: [`ios/Runner/IOS_PUSH_SETUP.md`](ios/Runner/IOS_PUSH_SETUP.md)

---

## 4. Admin — sending notifications

No extra admin config. Use **Notifications** page (`/notifications`):

1. Compose title + body + audience
2. Submit → creates in-app notification + triggers push dispatch

Admin login: `admin@orange.com` / `admin123`

---

## 5. Verify end-to-end

### Android

1. **Backend live:** `GET /notification/api/v1/push/status` → `fcmEnabled: true`
2. **Install APK** on a physical Android device
3. **Login** as `demo@orange.com` + OTP
4. **Admin** sends notification → push + in-app gallery

### iOS

1. Complete [iOS setup](#ios-push) (`GoogleService-Info.plist` + APNs `.p8`)
2. Run `./build-ios-demo.sh` on a **physical iPhone**
3. Login + allow notifications
4. Admin sends notification → push + in-app gallery

> iOS Simulator: in-app notifications work; FCM push delivery requires a real device + APNs key.

Check push audit (admin JWT):

```bash
curl -H "Authorization: Bearer <admin-token>" \
  http://127.0.0.1:8090/notification/api/v1/push/audit?limit=10
```

---

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `mode: "dry-run"` | Set `FCM_ENABLED=true` in `.env`, redeploy notification-service |
| No push on device | Rebuild APK with `PUSH_ENABLED=true`; check app notification permission |
| Token not registered | Login on device; check `POST /users/:id/device-token` in gateway logs |
| FCM 401/403 | Regenerate service account key; enable Firebase Cloud Messaging API (V1) in GCP |
| Push works, in-app missing | survey-service issue — check `/survey/api/v1/notifications` |
| iOS no push | Run `./scripts/setup-ios-firebase.sh`; upload APNs `.p8` to Firebase; use physical iPhone |

---

## 7. Safe to share vs vault only

| OK to share internally | Vault / secure transfer only |
|------------------------|------------------------------|
| Firebase project ID | Service account JSON |
| Package name `com.myboss.myboss_mobile` | APNs `.p8` key |
| iOS bundle ID `com.myboss.mybossMobile` | `GoogleService-Info.plist` if policy requires |
| Confirmation FCM API enabled | `google-services.json` if policy requires |

---

## Related docs

- [`architecture/GALLERY_NOTIFICATIONS.md`](architecture/GALLERY_NOTIFICATIONS.md) — in-app vs push design
- [`deployment/DEMO_TUNNEL_AND_APK.md`](deployment/DEMO_TUNNEL_AND_APK.md) — external APK + tunnel
- [`api/API_OVERVIEW.md`](api/API_OVERVIEW.md) — notification + device-token endpoints
