# Push notifications — Firebase setup

Firebase project: **`my-customer-my-boss`**

Console: https://console.firebase.google.com/project/my-customer-my-boss

---

## Architecture

```
Admin → POST /api/v1/notifications
     → myboss-api (in-app truth + gallery + FCM HTTP v1)
     → device token lookup (same process)
     → FCM → mobile PushService
```

In-app notifications work without FCM. Push requires backend FCM enabled **and** mobile built with `PUSH_ENABLED=true`.

---

## 1. Firebase project files

| File | Location | Status |
|------|----------|--------|
| `google-services.json` | `myboss-mobile/android/app/` | ✅ `my-customer-my-boss` |
| `firebase_options.dart` | `myboss-mobile/lib/` | ✅ Android + iOS |
| Service account JSON | `myboss-platform/secrets/fcm-service-account.json` | ⚠️ Must be Admin SDK for **this** project |
| `GoogleService-Info.plist` | `myboss-mobile/ios/Runner/` | ✅ `my-customer-my-boss` |
| APNs `.p8` key | Firebase Console → Cloud Messaging | ⚠️ Required for iOS push delivery |

**Never commit** `secrets/fcm-service-account.json` or service account keys to git.

---

## 2. Backend configuration

Add to **`myboss-platform/.env`** (Docker reads this file):

```env
FCM_ENABLED=true
FCM_PROJECT_ID=my-customer-my-boss
FCM_SERVICE_ACCOUNT_PATH=/run/secrets/fcm-service-account.json
NOTIFICATION_SERVICE_URL=http://127.0.0.1:3001/api/v1
PUSH_DISPATCH_ENABLED=true
```

Place the downloaded Firebase Admin SDK JSON at:

```
myboss-platform/secrets/fcm-service-account.json
```

Redeploy:

```bash
cd myboss-platform
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/push/status
```

Expected:

```bash
curl http://127.0.0.1:3001/api/v1/push/status
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

```bash
flutter build apk --release \
  --dart-define=API_HOST=<host> \
  --dart-define=API_PORT=3001 \
  --dart-define=DEMO_MODE=false \
  --dart-define=PUSH_ENABLED=true
```

### iOS push

Native iOS plumbing is in place (entitlements, AppDelegate, background modes). You still need Firebase + Apple credentials:

1. Register iOS app in Firebase — bundle ID **`com.myboss.mybossMobile`**
2. Download `GoogleService-Info.plist` into `myboss-mobile/ios/Runner/`
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
  http://127.0.0.1:3001/api/v1/push/audit?limit=10
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
| iOS no push | Add `GoogleService-Info.plist`; upload APNs `.p8` to Firebase; use a physical iPhone |

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
- [`INSTALL.md`](INSTALL.md) — new machine install & run
- [`api/API_OVERVIEW.md`](api/API_OVERVIEW.md) — notification + device-token endpoints
- [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md) — FCM / GitLab vars
