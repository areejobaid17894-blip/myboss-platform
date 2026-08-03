# my boss app — Orange Apigee Connection Guide

**Audience:** Apigee / API platform team  
**Purpose:** Route mobile app, admin portal, and chat APIs through Apigee to demo backend

---

## 1. Architecture

```
Mobile App  ──┐
Admin Portal ─┼──►  Orange Apigee  ──►  Demo VM / Gateway (ports 3001–3005 or 8090)
              │
Native Chat   ─┘   (REST via config proxy — no external chat CDN)
```

- **All REST API traffic** goes through Apigee
- **Chat** uses native REST messaging on the **config** proxy (`/config/api/v1/chat/*`)
- Full chat spec: [`docs/api/CHAT_API.md`](../../api/CHAT_API.md)

---

## 2. API base URL (demo)

```
https://api-demo.orange.com
```

---

## 3. Proxy routes to create

| Apigee proxy path | Target (demo VM) | Methods |
|-------------------|------------------|---------|
| `/auth/api/v1/**` | `http://<VM_IP>:3001/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/user/api/v1/**` | `http://<VM_IP>:3002/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/config/api/v1/**` | `http://<VM_IP>:3003/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/squad/api/v1/**` | `http://<VM_IP>:3004/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |
| `/survey/api/v1/**` | `http://<VM_IP>:3005/api/v1/**` | GET, POST, PUT, DELETE, OPTIONS |

Example URLs:

```
https://api-demo.orange.com/auth/api/v1/auth/sign-in
https://api-demo.orange.com/auth/api/v1/auth/verify-2fa
https://api-demo.orange.com/config/api/v1/chat/messages
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

See: [`docs/architecture/APIGEE_CHAT.md`](../../architecture/APIGEE_CHAT.md)

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

---

## 8. Client configuration after Apigee is live

### Admin portal

```env
VITE_AUTH_API_URL=https://api-demo.orange.com/auth/api/v1
VITE_USER_API_URL=https://api-demo.orange.com/user/api/v1
VITE_CONFIG_API_URL=https://api-demo.orange.com/config/api/v1
VITE_SURVEY_API_URL=https://api-demo.orange.com/survey/api/v1
```

### Mobile app

```bash
fvm flutter build web --dart-define=DEMO_MODE=true --base-href=/app/
# or use: myboss-mobile/build-demo-web.sh
```

---

## 9. Apigee verification

```bash
curl https://api-demo.orange.com/auth/api/v1/health
curl https://api-demo.orange.com/config/api/v1/chat/config

curl -X POST https://api-demo.orange.com/auth/api/v1/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}'
```

---

## 10. Checklist

- [ ] 5 API proxies (auth, user, config, squad, survey)
- [ ] JWT verify on protected routes (including chat messages)
- [ ] Orange error format preserved end-to-end
- [ ] Swagger reachable for QA (optional)
- [ ] Chat documented in config Swagger

---

*Orange — my boss app — Apigee Integration*
