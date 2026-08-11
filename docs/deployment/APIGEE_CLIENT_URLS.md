# Orange Apigee — client API URLs

**Status:** Primary API gateway for mobile and admin (nginx `:8090` is **local dev only**).

All REST traffic uses one public host with path-based routing to microservices.

---

## API gateway base URL

| Environment | Base URL | Used by |
|-------------|----------|---------|
| **Demo / UAT** | `https://api-demo.orange.com` | Mobile APK, admin `build:apigee`, integration tests |
| **Production** | `https://api.orange.com` | Production builds |

Override for a custom Apigee host:

```bash
export APIGEE_API_BASE_URL=https://your-apigee-host.example.com
```

---

## Service paths (same on Apigee and legacy nginx)

| Service | Apigee path prefix | Example |
|---------|-------------------|---------|
| Auth | `/auth/api/v1` | `POST …/auth/sign-in` |
| User | `/user/api/v1` | `GET …/users/{id}` |
| Config (+ chat) | `/config/api/v1` | `GET …/config/buildings` |
| Squad | `/squad/api/v1` | `POST …/squads/{id}/join` |
| Survey (+ gallery) | `/survey/api/v1` | `GET …/surveys/catalog` |
| Notification | `/notification/api/v1` | `GET …/push/status` |

### Full URL examples (demo)

```
https://api-demo.orange.com/auth/api/v1/auth/sign-in
https://api-demo.orange.com/auth/api/v1/auth/verify-2fa
https://api-demo.orange.com/user/api/v1/users/{id}
https://api-demo.orange.com/config/api/v1/chat/messages
https://api-demo.orange.com/squad/api/v1/squads
https://api-demo.orange.com/survey/api/v1/surveys/catalog
https://api-demo.orange.com/notification/api/v1/push/status
```

### Swagger (non-production)

```
https://api-demo.orange.com/auth/api/v1/docs
https://api-demo.orange.com/user/api/v1/docs
https://api-demo.orange.com/config/api/v1/docs
https://api-demo.orange.com/squad/api/v1/docs
https://api-demo.orange.com/survey/api/v1/docs
https://api-demo.orange.com/notification/api/v1/docs
```

### Health checks

Apigee has no single root `/health`. Probe per service:

```bash
curl https://api-demo.orange.com/auth/api/v1/health
curl https://api-demo.orange.com/user/api/v1/health
```

---

## Admin portal configuration

**Recommended** — one gateway variable (`.env.apigee`):

```env
VITE_API_GATEWAY_ORIGIN=https://api-demo.orange.com
VITE_APP_ENV=demo
```

Build:

```bash
cd myboss-admin
npm run build:apigee
# output: dist/
```

Or explicit per-service URLs:

```env
VITE_AUTH_API_URL=https://api-demo.orange.com/auth/api/v1
VITE_USER_API_URL=https://api-demo.orange.com/user/api/v1
VITE_CONFIG_API_URL=https://api-demo.orange.com/config/api/v1
VITE_SQUAD_API_URL=https://api-demo.orange.com/squad/api/v1
VITE_SURVEY_API_URL=https://api-demo.orange.com/survey/api/v1
```

**GitLab CI/CD:** set `VITE_API_GATEWAY_ORIGIN` (or each `VITE_*`) as protected variables on the admin project.

---

## Mobile app configuration

No `.env` file — pass at build/run time:

```bash
# Apigee demo (recommended for testers)
./build-apigee-android.sh

# Or explicitly:
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo

# Production
fvm flutter build apk --release \
  --dart-define=GATEWAY_ORIGIN=https://api.orange.com \
  --dart-define=ENV=production \
  --dart-define=PUSH_ENABLED=true
```

Default baked-in hosts (when no `--dart-define`):

- `ENV=demo` → `https://api-demo.orange.com`
- `ENV=production` → `https://api.orange.com`
- `ENV=development` → direct ports `3001–3005` on LAN

**GitLab CI/CD:** set `GATEWAY_ORIGIN` and `ENV` for mobile build jobs.

---

## Legacy nginx gateway (removed)

The former `nginx-api-gateway.conf` on port **8090** has been removed. Do not use `deploy-mobile-web.sh` — it prints a deprecation message.

Use **Apigee** for client API traffic or **direct ports** `:3001–3006` for local backend testing.

---

## Verification

```bash
# Auth health
curl -sS https://api-demo.orange.com/auth/api/v1/health

# Sign-in smoke test
curl -sS -X POST https://api-demo.orange.com/auth/api/v1/auth/sign-in \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@orange.com"}'

# Chat bootstrap (public)
curl -sS https://api-demo.orange.com/config/api/v1/chat/config
```

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [`../architecture/APIGEE_VS_NGINX.md`](../architecture/APIGEE_VS_NGINX.md) | Why Apigee replaced nginx for clients |
| [`pdf/03_APIGEE_CONNECTION.md`](pdf/03_APIGEE_CONNECTION.md) | Apigee proxy setup for platform team |
| [`ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md) | GitLab variable mapping |

---

*Orange — my boss app*
