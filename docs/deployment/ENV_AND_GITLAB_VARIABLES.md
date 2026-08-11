# Environment variables & GitLab CI/CD

This document lists **every configuration surface** for my boss app: local `.env` files, build-time flags, and how the same values will be stored as **GitLab CI/CD variables** when pipelines are wired up.

---

## Principles

| Rule | Detail |
|------|--------|
| **Templates in git** | `.env.example` files are committed — placeholders only, no real secrets |
| **Secrets stay local** | Copy to `.env` / `.env.development` on your machine; those paths are in `.gitignore` |
| **One source for Docker demo** | `myboss-platform/.env` is read by `docker-compose.demo.yml` for all backend containers |
| **Match tokens across repos** | `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN` must be identical in platform and backend when running npm dev |
| **Future: GitLab variables** | Production and shared demo hosts will inject the same keys via **Settings → CI/CD → Variables** — not committed files |

### Adding a variable in GitLab (when CI/CD is enabled)

1. Open the project in GitLab → **Settings → CI/CD → Variables**
2. **Add variable**
   - **Key:** exact name (e.g. `JWT_SECRET`)
   - **Value:** secret value
   - **Flags:** check **Mask variable** for secrets; check **Protect variable** if only protected branches may use it
   - **Type:** `Variable` for strings; `File` for JSON/key files (e.g. FCM service account)
3. In `.gitlab-ci.yml`, expose to jobs:

```yaml
variables:
  JWT_SECRET: $JWT_SECRET
```

Or for file-type secrets:

```yaml
before_script:
  - cp "$FCM_SERVICE_ACCOUNT_JSON" ./secrets/fcm-service-account.json
```

Group-level variables (shared across all four repos) are recommended for `JWT_SECRET`, `INTERNAL_SERVICE_TOKEN`, and Orange API credentials.

---

## File map (local development)

| File | Repo | Used by | Required when |
|------|------|---------|---------------|
| `.env` | `myboss-platform` | Docker demo stack | Always for Docker demo |
| `.env` | `myboss-backend` | `npm run start:dev` | Local backend without Docker |
| `.env.development` | `myboss-admin` | `npm run dev` (:5173) | Admin hot reload |
| `.env.local-demo` | `myboss-admin` | `npm run build:local-demo` | Optional custom admin build |
| `secrets/fcm-service-account.json` | `myboss-platform` | notification-service | Push notifications |
| *(none)* | `myboss-mobile` | — | Uses `--dart-define` at build/run |

Copy commands:

```bash
cd myboss-platform && cp .env.example .env
cd myboss-backend   && cp .env.example .env      # optional
cd myboss-admin     && cp .env.example .env.development   # optional
```

---

## Platform / backend — `myboss-platform/.env`

These variables are defined in `myboss-platform/.env.example` and passed into Docker containers via `docker/docker-compose.demo.yml`.

### Core security (required for non-dev)

| Variable | Description | Example | GitLab scope | Mask? |
|----------|-------------|---------|--------------|-------|
| `JWT_SECRET` | Signs access/refresh tokens | `openssl rand -base64 48` | Group | Yes |
| `INTERNAL_SERVICE_TOKEN` | Header `X-Internal-Service-Token` for service-to-service calls | `openssl rand -base64 32` | Group | Yes |
| `JWT_EXPIRES_IN` | Access token TTL | `15m` | Group | No |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token TTL | `7d` | Group | No |

### Environment mode

| Variable | Description | Demo value | GitLab scope |
|----------|-------------|------------|--------------|
| `NODE_ENV` | Node runtime mode | `development` / `demo` | Per env |
| `APP_ENV` | App behaviour (Swagger, 2FA) | `development` / `demo` / `uat` / `production` | Per env |

### Database (MariaDB)

| Variable | Description | Demo default | GitLab scope |
|----------|-------------|--------------|--------------|
| `DB_ENABLED` | `false` = in-memory; `true` = MariaDB | `false` | Per env |
| `MARIADB_HOST` | DB host | `mariadb` (Docker) / `localhost` | Per env |
| `MARIADB_PORT` | DB port | `3306` | Per env |
| `MARIADB_USER` | DB user | `myboss` | Per env |
| `MARIADB_PASSWORD` | DB password | `changeme` | Yes |
| `MARIADB_ROOT_PASSWORD` | Root password | `rootchangeme` | Yes |
| `MARIADB_DATABASE` | Shared DB name (all services) | `myboss` | Per env |
| `DB_SYNCHRONIZE` | TypeORM auto-sync (dev only) | `true` | Per env |
| `DB_LOGGING` | SQL logging | `false` | Per env |

### Service ports (local npm dev)

| Variable | Service | Default |
|----------|---------|---------|
| `AUTH_SERVICE_PORT` | auth-service | `3001` |
| `USER_SERVICE_PORT` | user-service | `3002` |
| `CONFIG_SERVICE_PORT` | config-service | `3003` |
| `SQUAD_SERVICE_PORT` | squad-service | `3004` |
| `SURVEY_SERVICE_PORT` | survey-service | `3005` |
| `NOTIFICATION_SERVICE_PORT` | notification-service | `3006` |

### Demo admin seed

| Variable | Description | Default | GitLab scope |
|----------|-------------|---------|--------------|
| `DEMO_ADMIN_EMAIL` | Seeded admin email | `admin@orange.com` | Per env |
| `DEMO_ADMIN_PASSWORD` | Seeded admin password | `admin123` | Yes (non-prod) |
| `DEMO_HOST` | Public IP/hostname for APK builds | your server IP | Per env |

### Two-factor / OTP

| Variable | Description | Demo | GitLab scope |
|----------|-------------|------|--------------|
| `TWO_FA_DEMO_ENABLED` | Auto-fill OTP in demo | `true` | Per env |
| `OTP_PROVIDER` | `demo` or `orange` | `demo` | Per env |
| `ORANGE_OTP_ENABLED` | Enable Orange email OTP | `false` | Per env |
| `ORANGE_SSO_TOKEN_URL` | Orange SSO token endpoint | Orange preprod URL | Per env |
| `ORANGE_SSO_CLIENT_ID` | SSO client id | *(from Orange)* | Yes |
| `ORANGE_SSO_CLIENT_SECRET` | SSO client secret | *(from Orange)* | Yes |
| `ORANGE_SSO_API_KEY` | Optional Apigee key for SSO | | Yes |
| `ORANGE_EMAIL_API_URL` | Orange email send API | preprod URL | Per env |
| `ORANGE_EMAIL_CLIENT_NAME` | Email client name | `sajelni` | Per env |
| `ORANGE_EMAIL_CHANNEL` | Email channel | `survey_app` | Per env |
| `ORANGE_EMAIL_TYPE` | Template type | `blank` / `blank_ar` | Per env |
| `ORANGE_EMAIL_API_KEY` | Apigee apiKey for email | | Yes |
| `ORANGE_OTP_FALLBACK_DEMO` | Fall back to demo OTP if Orange fails | `false` | Per env |

### Push notifications (Firebase)

| Variable | Description | GitLab scope | Type |
|----------|-------------|--------------|------|
| `FCM_ENABLED` | Send real FCM messages | Per env | Variable |
| `FCM_PROJECT_ID` | Firebase project id | Per env | Variable |
| `FCM_SERVICE_ACCOUNT_PATH` | Path inside container | `/run/secrets/fcm-service-account.json` | Variable |
| `FCM_SERVICE_ACCOUNT_HOST_PATH` | Host path mounted into Docker | `./secrets/fcm-service-account.json` | Variable |
| `FCM_SERVICE_ACCOUNT_JSON` | *(GitLab only)* full JSON content | Group | **File** |
| `PUSH_DISPATCH_ENABLED` | Enable push dispatch pipeline | `true` | Per env |
| `NOTIFICATION_SERVICE_URL` | Internal notification URL | `http://notification-service:3006/api/v1` | Per env |

Setup guide: [`../PUSH_FIREBASE_SETUP.md`](../PUSH_FIREBASE_SETUP.md)

### Chat (Tawk.to demo)

| Variable | Description | Default |
|----------|-------------|---------|
| `CHAT_ENABLED` | Enable chat module | `true` |
| `TAWK_PROPERTY_ID` | Tawk property | `demo` |
| `TAWK_WIDGET_ID` | Tawk widget | `default` |
| `CHAT_EVENT_DAILY_USERS` | Demo capacity hint | `1500` |
| `CHAT_EVENT_DURATION_DAYS` | Demo duration | `7` |
| `CHAT_APIGEE_BASE_PATH` | Production path prefix | `/config/api/v1/chat` |

### Localization (Phrase — optional)

| Variable | Description | GitLab scope |
|----------|-------------|--------------|
| `PHRASE_PROJECT_ID` | Phrase project | Group |
| `PHRASE_ACCESS_TOKEN` | Phrase API token | Yes |

### CORS (optional)

| Variable | Description |
|----------|-------------|
| `CORS_ALLOWED_ORIGINS` | Comma-separated extra origins |

### Redis (optional, future)

| Variable | Default |
|----------|---------|
| `REDIS_HOST` | `localhost` |
| `REDIS_PORT` | `6379` |

---

## Admin portal — `myboss-admin/.env.development`

Vite exposes only variables prefixed with `VITE_`.

| Variable | Description | Local dev (`npm run dev`) | Apigee build (`npm run build:apigee`) |
|----------|-------------|---------------------------|---------------------------------------|
| `VITE_API_GATEWAY_ORIGIN` | Single Apigee base (**recommended**) | — | `https://api-demo.orange.com` |
| `VITE_AUTH_API_URL` | Auth API base | `http://localhost:3001/api/v1` | *(derived from gateway)* |
| `VITE_USER_API_URL` | User API base | `http://localhost:3002/api/v1` | *(derived from gateway)* |
| `VITE_CONFIG_API_URL` | Config API base | `http://localhost:3003/api/v1` | *(derived from gateway)* |
| `VITE_SQUAD_API_URL` | Squad API base | `http://localhost:3004/api/v1` | *(derived from gateway)* |
| `VITE_SURVEY_API_URL` | Survey API base | `http://localhost:3005/api/v1` | *(derived from gateway)* |
| `VITE_APP_ENV` | UI environment label | `development` | `demo` |

**GitLab (admin build job):** set the same `VITE_*` variables for each environment (demo vs production Apigee base URL). They are baked in at **build time**, not runtime.

Template: `myboss-admin/.env.example`

---

## Mobile app — `--dart-define` (no `.env` file)

The Flutter app does not use a committed `.env`. Pass flags when running or building:

| Dart define | Purpose | Typical demo value |
|-------------|---------|-------------------|
| `DEMO_MODE` | Auto-fill OTP, demo behaviour | `true` |
| `GATEWAY_ORIGIN` | Primary API gateway URL | `https://api-demo.orange.com` |
| `APIGEE_API_BASE_URL` | Shell env for build scripts | `https://api-demo.orange.com` |
| `API_HOST` | Single host fallback | Mac LAN IP |
| `API_HOSTS` | Comma-separated hosts to probe | `tunnel-host,192.168.1.9` |
| `PUSH_ENABLED` | Register FCM device tokens | `true` (APK scripts set this) |
| `ENV` | Dev direct-port mode | `development` |

Examples:

```bash
# Apigee demo (recommended)
fvm flutter run --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com --dart-define=ENV=demo

# Local emulator (legacy nginx)
fvm flutter run --dart-define=DEMO_MODE=true --dart-define=GATEWAY_ORIGIN=http://10.0.2.2:8090
```

**GitLab (mobile build job):** pass the same values to `flutter build apk`:

```yaml
script:
  - flutter build apk --release
      --dart-define=DEMO_MODE=$DEMO_MODE
      --dart-define=GATEWAY_ORIGIN=$GATEWAY_ORIGIN
      --dart-define=PUSH_ENABLED=true
```

Scripts that encode these: `build-local-android.sh`, `build-external-android.sh`, `build-ios-demo.sh`

---

## Generated / runtime files (never commit)

| Path | Created by |
|------|------------|
| `myboss-platform/demo-public-url.txt` | `start-demo-tunnel.sh` |
| `myboss-platform/secrets/fcm-service-account.json` | Firebase Console download |
| `myboss-mobile/android/local.properties` | Android Studio |
| `**/node_modules/`, `**/build/`, `**/dist/` | install / build |

---

## GitLab variable checklist (recommended group variables)

Use this when setting up GitLab for the four repos:

| Priority | Variable | Notes |
|----------|----------|-------|
| P0 | `JWT_SECRET` | Mask, protect on production |
| P0 | `INTERNAL_SERVICE_TOKEN` | Mask |
| P0 | `MARIADB_PASSWORD` | When `DB_ENABLED=true` |
| P1 | `DEMO_ADMIN_PASSWORD` | Non-prod only |
| P1 | `ORANGE_SSO_CLIENT_ID` / `ORANGE_SSO_CLIENT_SECRET` | Production OTP |
| P1 | `ORANGE_EMAIL_API_KEY` | Production email |
| P1 | `FCM_SERVICE_ACCOUNT_JSON` | File type; mount in notification-service |
| P2 | `PHRASE_ACCESS_TOKEN` | Mobile l10n pipeline |
| P2 | `VITE_*` (×5) | Admin build per environment |
| P2 | `GATEWAY_ORIGIN` | Mobile APK CI |

---

## Related docs

| Topic | Link |
|-------|------|
| New laptop + new phone setup | [`../NEW_DEVICE_SETUP.md`](../NEW_DEVICE_SETUP.md) |
| Local env quick start | [`ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) |
| CI/CD overview | [`../cicd/CI_CD.md`](../cicd/CI_CD.md) |
| DevOps / deploy | [`../devops/DEVOPS.md`](../devops/DEVOPS.md) |

---

*Orange — my boss app*
