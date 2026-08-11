# my boss app — Orange Apigee Connection Guide

**Audience:** Apigee / API platform team, DevOps  
**Purpose:** Route mobile app, admin portal, and chat APIs through Apigee to the demo backend

---

## 1. Architecture

```
Mobile app / Admin SPA
        │
        ▼
Orange Apigee  (https://api-demo.orange.com)
        │
        ├── /auth/api/v1/**         → auth-service      :3001
        ├── /user/api/v1/**         → user-service      :3002
        ├── /config/api/v1/**       → config-service    :3003  (+ chat)
        ├── /squad/api/v1/**        → squad-service     :3004
        ├── /survey/api/v1/**       → survey-service    :3005
        └── /notification/api/v1/** → notification-service :3006
```

- **All REST API traffic** goes through Apigee — there is no nginx API gateway in this project.
- **Chat** uses native REST on the **config** proxy (`/config/api/v1/chat/*`).
- Full chat spec: [`../api/CHAT_API.md`](../api/CHAT_API.md)

---

## 2. API base URLs

| Environment | Base URL |
|-------------|----------|
| Demo | `https://api-demo.orange.com` |
| Production | `https://api.orange.com` |

Client URL table: [`APIGEE_CLIENT_URLS.md`](APIGEE_CLIENT_URLS.md)

---

## 3. Proxy routes to create

| Apigee proxy path | Target (demo VM) | Methods |
|-------------------|------------------|---------|
| `/auth/api/v1/**` | `http://<VM_IP>:3001/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/user/api/v1/**` | `http://<VM_IP>:3002/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/config/api/v1/**` | `http://<VM_IP>:3003/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/squad/api/v1/**` | `http://<VM_IP>:3004/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/survey/api/v1/**` | `http://<VM_IP>:3005/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/notification/api/v1/**` | `http://<VM_IP>:3006/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |

Example URLs:

```
https://api-demo.orange.com/auth/api/v1/auth/sign-in
https://api-demo.orange.com/auth/api/v1/auth/verify-2fa
https://api-demo.orange.com/config/api/v1/chat/messages
https://api-demo.orange.com/squad/api/v1/squads
https://api-demo.orange.com/survey/api/v1/surveys/catalog
```

---

## 4. Recommended Apigee policies

### All proxies
- TLS termination at Apigee
- Spike arrest: 100 req/min/IP
- CORS for admin + mobile web origins

### Authenticated routes
- Verify JWT (Bearer from auth-service)
- Pass `Authorization` and `Accept-Language` unchanged

### Public routes (no JWT)
- `POST /auth/api/v1/auth/sign-in`, `/sign-up`, `/verify-2fa`, `/resend-otp`, `/refresh`
- `GET /config/api/v1/config/*` (read-only reference data)
- `GET /config/api/v1/chat/config`, `/chat/health`
- `GET /**/health`

### Internal routes (service token — do not expose on public Apigee product)
- `POST /user/api/v1/users/ensure` — requires `X-Internal-Service-Token`
- `PUT /user/api/v1/users/:id/squad` — requires service token **or** admin JWT

---

## 5. Chat endpoints (config proxy)

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /config/api/v1/chat/config` | Public | Chat bootstrap metadata |
| `GET /config/api/v1/chat/health` | Public | Monitoring |
| `GET /config/api/v1/chat/visitor` | JWT | User identity |
| `GET /config/api/v1/chat/messages` | JWT | Poll direct messages |
| `POST /config/api/v1/chat/messages` | JWT | Send direct message |

See: [`../architecture/APIGEE_CHAT.md`](../architecture/APIGEE_CHAT.md)

---

## 6. Error response format

All services return Orange Common Response errors:

```json
{ "code": 41, "reason": "Invalid credentials", "message": "..." }
```

---

## 7. Swagger (non-production)

Each service exposes OpenAPI at `/api/v1/docs` when enabled:

```
https://api-demo.orange.com/auth/api/v1/docs
https://api-demo.orange.com/config/api/v1/docs   ← Chat tag
```

Local (direct ports): `http://127.0.0.1:3001/api/v1/docs` … `:3006`

---

## 8. Client configuration after Apigee is live

### Admin portal

**Recommended** — single gateway origin (`.env.apigee`):

```env
VITE_API_GATEWAY_ORIGIN=https://api-demo.orange.com
VITE_APP_ENV=demo
```

```bash
cd myboss-admin
npm run build:apigee
```

Docker admin (port 8081) is built with Apigee URLs by default.

### Mobile app

```bash
cd myboss-mobile
./build-apigee-android.sh

# Or run on device/emulator:
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

---

## 9. Apigee verification

```bash
curl https://api-demo.orange.com/auth/api/v1/health
curl https://api-demo.orange.com/config/api/v1/chat/config

curl -X POST https://api-demo.orange.com/auth/api/v1/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}'

# Or via platform script:
cd myboss-platform
./scripts/verify-mobile-api.sh --apigee
```

---

## 10. Checklist

- [ ] 6 API proxies (auth, user, config, squad, survey, notification)
- [ ] JWT verify on protected routes (including chat messages)
- [ ] Orange error format preserved end-to-end
- [ ] Swagger reachable for QA (optional)
- [ ] Chat documented in config Swagger
- [ ] Admin SPA and mobile APK point at Apigee base URL

---

*Orange — my boss app — Apigee Integration*
